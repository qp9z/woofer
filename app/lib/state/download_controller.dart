import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/media_format.dart';
import '../models/video_info.dart';
import '../services/api_exception.dart';
import '../services/cover_fetcher.dart';
import '../services/foreground_service.dart';
import '../services/history_service.dart';
import '../services/media_processor.dart';
import '../services/storage_service.dart';
import '../services/ytdlp_extractor.dart';
// Pure display helpers (no widgets) — reused so the notification is worded
// exactly like the screens.
import '../ui/format_utils.dart';
import 'download_state.dart';

/// Injectable services — override these in tests. Everything runs on-device;
/// yt-dlp (Chaquopy) is the single extractor for every site, YouTube included.
final ytdlpExtractorProvider = Provider<YtdlpExtractor>((ref) => YtdlpExtractor());
final mediaProcessorProvider = Provider<MediaProcessor>((ref) => MediaProcessor());
final storageServiceProvider = Provider<StorageService>((ref) => StorageService());
final foregroundServiceProvider = Provider<ForegroundService>((ref) => ForegroundService());
final coverFetcherProvider = Provider<CoverFetcher>((ref) => const CoverFetcher());
final historyServiceProvider = FutureProvider<HistoryService>((ref) => HistoryService.open());

/// Past downloads, newest first. Invalidated whenever a download is recorded.
final historyListProvider = FutureProvider<List<HistoryEntry>>((ref) async {
  final history = await ref.watch(historyServiceProvider.future);
  return history.getAll();
});

/// The one entry point for the download flow. Drives [DownloadState] through
/// idle → loading → formatsReady → downloading → processing → done | error.
final downloadControllerProvider =
    NotifierProvider<DownloadController, DownloadState>(DownloadController.new);

class DownloadController extends Notifier<DownloadState> {
  String? _url;
  VideoInfo? _info;
  MediaFormat? _selected;
  bool _cancelled = false;

  @override
  DownloadState build() {
    // The notification's Cancel button lands here — it's the only way to stop a
    // download once the app has been closed.
    ref.read(foregroundServiceProvider).onCancelRequested(cancel);
    return const Idle();
  }

  YtdlpExtractor get _ytdlp => ref.read(ytdlpExtractorProvider);
  MediaProcessor get _processor => ref.read(mediaProcessorProvider);
  StorageService get _storage => ref.read(storageServiceProvider);
  ForegroundService get _foreground => ref.read(foregroundServiceProvider);
  CoverFetcher get _cover => ref.read(coverFetcherProvider);

  /// Resolve [url] to formats via yt-dlp. Moves to [FormatsReady] or [Failed].
  Future<void> extract(String url) async {
    _url = url;
    state = const Loading();
    try {
      _info = await _ytdlp.extractInfo(url);
      state = FormatsReady(_info!);
    } on ApiException catch (e) {
      state = Failed(e.code, e.message);
    }
  }

  /// Choose which format to download. No-op unless in [FormatsReady].
  void selectFormat(MediaFormat format) {
    final s = state;
    if (s is FormatsReady) state = s.select(format);
  }

  /// After a failure: reopen format selection if we already resolved the video
  /// (so the sheet comes back), otherwise re-resolve the last URL from scratch.
  void retry() {
    final info = _info;
    final url = _url;
    if (info != null) {
      state = FormatsReady(info, selected: _selected);
    } else if (url != null) {
      extract(url);
    }
  }

  /// Back to a clean slate.
  void reset() {
    _url = null;
    _info = null;
    _selected = null;
    state = const Idle();
  }

  /// Abort the flow and return to format selection.
  ///
  /// [_cancelled] stops the pipeline at the next step boundary, and the extractor
  /// is told to abort the transfer itself — otherwise cancelling a 4K download
  /// only registered once its last byte had arrived, minutes later, which made
  /// the notification's Cancel button look broken.
  // ponytail: an ffmpeg merge already under way still runs to completion (its
  // output is then discarded). FFmpegKit.cancel() if that ever matters.
  void cancel() {
    _cancelled = true;
    unawaited(_ytdlp.cancel());
    final info = _info;
    if (info != null) state = FormatsReady(info, selected: _selected);
  }

  /// Download the selected format: fetch stream(s), merge/transcode if needed,
  /// save to Downloads, record history. No-op unless a format is selected.
  Future<void> download() async {
    final ready = state;
    if (ready is! FormatsReady || ready.selected == null) return;
    final fmt = ready.selected!;
    final info = ready.info;
    final url = _url;
    if (url == null) return;

    _info = info;
    _selected = fmt;
    _cancelled = false;
    final temps = <String>[];

    // Set Downloading synchronously (before any await) so a cancel() racing the
    // first await still wins the final state.
    state = Downloading(format: fmt, received: 0, total: fmt.filesize ?? -1);

    // Pin the process for the whole pipeline. Everything below runs in this
    // isolate, so without this Android is free to reclaim us the moment the user
    // leaves the app — mid-transfer, mid-merge, or mid-save.
    final label = info.title ?? 'Downloading';
    await _foreground.show(label, text: 'Starting…');
    var shownPercent = -1;

    // Captured where the outcome actually happens, never re-read from `state` in
    // the finally: HomeShell listens for Done and calls reset(), which lands
    // before the finally does, so by then the state is Idle again.
    ({String title, String text, String? uri, String? mime})? outcome;

    // A fresh, empty scratch dir per download. yt-dlp names files by title only,
    // so sharing systemTemp let a leftover .part from a prior/cancelled attempt
    // get *resumed* — a byte-range past EOF returns HTTP 416 — or a stale file of
    // the wrong resolution get silently reused. A private dir has neither.
    final tmpDir = await Directory.systemTemp.createTemp('woofer_dl_');
    try {
      // 1. Download the selected stream.
      final primary = await _downloadFormat(fmt, tmpDir.path, onProgress: (received, total) {
        if (_cancelled) return;
        state = Downloading(format: fmt, received: received, total: total);
        // Only touch the notification when the whole percent changes — progress
        // hooks fire far too often to cross the platform channel every time.
        final percent = total > 0 ? (received * 100) ~/ total : -1;
        if (percent != shownPercent) {
          shownPercent = percent;
          final of = total > 0 ? ' of ${formatBytes(total)}' : '';
          _foreground.show(
            label,
            text: 'Downloading · ${formatBytes(received)}$of',
            percent: percent,
          );
        }
      });
      temps.add(primary);
      if (_cancelled) return;

      // 2. Post-process: merge video-only with audio, or transcode audio to MP3.
      final String finalPath;
      final String ext;
      final String mime;
      if (fmt.needsMerge) {
        final audioFmt = _bestAudio(info);
        if (audioFmt == null) {
          throw const ApiException(code: ApiErrorCode.unknown, message: 'No audio track available to merge.');
        }
        final audioPath = await _downloadFormat(audioFmt, tmpDir.path);
        temps.add(audioPath);
        if (_cancelled) return;
        state = Processing(fmt, 'Merging video and audio');
        // Indeterminate — a 4K merge isn't instant and ffmpeg gives no percentage.
        await _foreground.show(label, text: 'Merging video and audio');
        finalPath = await _processor.mergeVideoAudio(primary, audioPath);
        temps.add(finalPath);
        // The processor picks the container that fits the streams (mp4/webm/mkv);
        // save + record with the matching extension and MIME, not a hardcoded mp4.
        ext = _extOf(finalPath);
        mime = _videoMime(ext);
      } else if (!fmt.hasVideo) {
        state = Processing(fmt, 'Converting to MP3');
        await _foreground.show(label, text: 'Converting to MP3');
        // Artwork, so the file looks like music in a player. Null when there's no
        // thumbnail or the fetch fails; toMp3 then just skips the embed.
        final cover = await _cover.fetch(info.thumbnail, tmpDir.path);
        if (cover != null) temps.add(cover);
        finalPath = await _processor.toMp3(primary, coverPath: cover);
        temps.add(finalPath);
        ext = 'mp3';
        mime = 'audio/mpeg';
      } else {
        finalPath = primary; // muxed video+audio — ready as-is
        ext = fmt.ext ?? 'mp4';
        mime = 'video/mp4';
      }
      if (_cancelled) return;

      // 3. Save to public Downloads. Its own phase: copying 1.3 GB into MediaStore
      // is slow enough that a stalled "Merging" would read as a hang.
      await _foreground.show(label, text: 'Saving to Downloads');
      final saved = await _storage.saveToDownloads(
        File(finalPath),
        fileName: _fileName(info.title, ext),
        mimeType: mime,
      );
      if (_cancelled) return;
      if (!saved.isSuccess) {
        final message = saved.message ?? 'Could not save the file.';
        state = Failed(ApiErrorCode.unknown, message);
        outcome = (title: describeError(ApiErrorCode.unknown), text: message, uri: null, mime: null);
        return;
      }

      // 4. Record history. Store the *uri*, not `saved.path`: on API 29+ the path is
      // MediaStore's display path ("Download/woofer/x.mp4"), which nothing can
      // resolve — and the Library tab hands this string straight back to
      // openFile/shareFile, so a display path there means tapping a row does nothing.
      final out = File(finalPath);
      // Real bytes on disk; fmt.filesize is yt-dlp's per-stream estimate, which is
      // wrong for a merge (video only) and for an MP3 transcode.
      final bytes = await out.exists() ? await out.length() : fmt.filesize;
      final stored = saved.uri ?? saved.path ?? finalPath;
      await _recordHistory(info, url, stored, fmt, bytes);
      outcome = (
        title: label,
        text: 'Saved to Downloads · tap to open',
        uri: saved.uri,
        mime: mime,
      );
      state = Done(path: saved.path ?? stored, uri: saved.uri);
    } on ApiException catch (e) {
      if (!_cancelled) {
        state = Failed(e.code, e.message);
        outcome = (title: describeError(e.code), text: e.message, uri: null, mime: null);
      }
    } finally {
      for (final p in temps) {
        await _deleteQuietly(p);
      }
      await _deleteDirQuietly(tmpDir); // nuke any yt-dlp leftovers (.part, fragments)
      // Release the process last: cleanup is part of the download too. The result
      // has to be posted *after*, because stopping the service takes its own
      // notification down with it.
      await _foreground.hide();
      // Nothing to say after a cancel — the user did that themselves.
      if (outcome != null) {
        await _foreground.showResult(
          outcome.title,
          outcome.text,
          uri: outcome.uri,
          mimeType: outcome.mime,
        );
      }
    }
  }

  /// Download one [format] into [dir] (a private scratch dir) via yt-dlp.
  Future<String> _downloadFormat(
    MediaFormat format,
    String dir, {
    void Function(int received, int total)? onProgress,
  }) =>
      _ytdlp.download(_url!, format.formatId, onProgress: onProgress, dir: dir);

  /// Best audio-only format to pair with a video-only stream (largest = best).
  MediaFormat? _bestAudio(VideoInfo info) {
    final audios = info.formats.where((f) => f.hasAudio && !f.hasVideo).toList();
    if (audios.isEmpty) return null;
    audios.sort((a, b) => (b.filesize ?? 0).compareTo(a.filesize ?? 0));
    return audios.first;
  }

  Future<void> _recordHistory(
      VideoInfo info, String url, String path, MediaFormat format, int? size) async {
    try {
      final history = await ref.read(historyServiceProvider.future);
      await history.add(HistoryEntry(
        title: info.title,
        thumbnail: info.thumbnail,
        sourceUrl: url,
        filePath: path,
        format: format.resolution ?? format.note ?? format.formatId,
        size: size,
      ));
      ref.invalidate(historyListProvider); // the Library tab picks it up
    } catch (_) {
      // ponytail: history is best-effort — logging failure must not fail a saved download.
    }
  }

  String _fileName(String? title, String ext) {
    final raw = (title == null || title.trim().isEmpty)
        ? 'woofer_${DateTime.now().millisecondsSinceEpoch}'
        : title.trim();
    final safe = raw.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return '$safe.$ext';
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  Future<void> _deleteDirQuietly(Directory dir) async {
    try {
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }

  String _extOf(String path) {
    final i = path.lastIndexOf('.');
    return i < 0 ? 'mp4' : path.substring(i + 1).toLowerCase();
  }

  String _videoMime(String ext) => switch (ext) {
        'webm' => 'video/webm',
        'mkv' => 'video/x-matroska',
        _ => 'video/mp4',
      };
}
