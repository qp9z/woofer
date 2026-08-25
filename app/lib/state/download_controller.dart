import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/media_format.dart';
import '../models/video_info.dart';
import '../services/api_exception.dart';
import '../services/cover_fetcher.dart';
import '../services/filename.dart';
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
final ytdlpExtractorProvider = Provider<YtdlpExtractor>(
  (ref) => YtdlpExtractor(),
);
final mediaProcessorProvider = Provider<MediaProcessor>(
  (ref) => MediaProcessor(),
);
final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(),
);
final foregroundServiceProvider = Provider<ForegroundService>(
  (ref) => ForegroundService(),
);
final coverFetcherProvider = Provider<CoverFetcher>(
  (ref) => const CoverFetcher(),
);
final historyServiceProvider = FutureProvider<HistoryService>(
  (ref) => HistoryService.open(),
);

typedef DownloadTempDirectoryFactory = Future<Directory> Function();

/// Injectable because running out of temporary storage is a real download
/// failure which must still release the foreground service and controller.
final downloadTempDirectoryProvider = Provider<DownloadTempDirectoryFactory>(
  (ref) =>
      () => Directory.systemTemp.createTemp('woofer_dl_'),
);

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
  int _extractGeneration = 0;
  _DownloadOperation? _activeDownload;

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
  DownloadTempDirectoryFactory get _createTempDirectory =>
      ref.read(downloadTempDirectoryProvider);

  /// Whether a URL can be resolved right now. Concurrent extractions are safe
  /// (the newest one wins), but a running download owns the native yt-dlp
  /// channel until it has completely unwound.
  bool get canExtract => _activeDownload == null;

  /// Resolve [url] to formats via yt-dlp. Moves to [FormatsReady] or [Failed].
  Future<void> extract(String url) async {
    // The native bridge and its progress callback support one download at a
    // time. Reject replacement links until the current pipeline (including its
    // cleanup) is finished, whether this came from Fetch or a share intent.
    if (!canExtract) return;

    // More than one extraction may be in flight (for example, two rapid share
    // intents). Only the newest is allowed to publish a result.
    final generation = ++_extractGeneration;
    _url = url;
    _info = null;
    _selected = null;
    state = const Loading();
    try {
      final info = await _ytdlp.extractInfo(url);
      if (generation != _extractGeneration || !canExtract) return;
      _info = info;
      state = FormatsReady(info);
    } on ApiException catch (e) {
      if (generation != _extractGeneration || !canExtract) return;
      state = Failed(e.code, e.message);
    } catch (error, stackTrace) {
      if (generation != _extractGeneration || !canExtract) return;
      _logUnexpected('extract', error, stackTrace);
      state = Failed(ApiErrorCode.unknown, _unexpectedExtractMessage(error));
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
    if (!canExtract) return;
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
    // Invalidate an extraction which may still complete after the UI resets.
    _extractGeneration++;
    _url = null;
    _info = null;
    _selected = null;
    state = const Idle();
  }

  /// Abort the flow and return to format selection.
  ///
  /// The operation's cancellation flag stops the pipeline at the next step
  /// boundary, the extractor is told to abort the transfer itself — otherwise
  /// cancelling a 4K download only registered once its last byte had arrived,
  /// minutes later, which made the notification's Cancel button look broken —
  /// and an in-flight ffmpeg merge/transcode is cancelled too, so the user isn't
  /// left waiting out minutes of re-encoding they already asked to stop.
  void cancel() {
    final operation = _activeDownload;
    if (operation == null || operation.cancelled) return;
    operation.cancelled = true;
    unawaited(_ytdlp.cancel());
    unawaited(_processor.cancel());
    // Keep the active state until the native call has actually unwound. This
    // prevents an immediate retry from sharing YtdlpExtractor's one progress
    // callback with the cancelled transfer. The finally block restores the
    // selected format once cleanup is complete.
  }

  /// Download the selected format: fetch stream(s), merge/transcode if needed,
  /// save to Downloads, record history. No-op unless a format is selected.
  Future<void> download() async {
    if (_activeDownload != null) return;
    final ready = state;
    if (ready is! FormatsReady || ready.selected == null) return;
    final fmt = ready.selected!;
    final info = ready.info;
    final url = _url;
    if (url == null) return;

    final operation = _DownloadOperation(url: url, info: info, format: fmt);
    _activeDownload = operation;
    _info = info;
    _selected = fmt;
    final temps = <String>[];

    // Set Downloading synchronously (before any await) so a cancel() racing the
    // first await still wins the final state.
    state = Downloading(format: fmt, received: 0, total: fmt.filesize ?? -1);

    // Pin the process for the whole pipeline. Everything below runs in this
    // isolate, so without this Android is free to reclaim us the moment the user
    // leaves the app — mid-transfer, mid-merge, or mid-save.
    final label = info.title ?? 'Downloading';
    var shownPercent = -1;

    // Captured where the outcome actually happens, never re-read from `state` in
    // the finally: HomeShell listens for Done and calls reset(), which lands
    // before the finally does, so by then the state is Idle again.
    ({String title, String text, String? uri, String? mime})? outcome;
    Directory? tmpDir;

    // A fresh, empty scratch dir per download. yt-dlp names files by title only,
    // so sharing systemTemp let a leftover .part from a prior/cancelled attempt
    // get *resumed* — a byte-range past EOF returns HTTP 416 — or a stale file of
    // the wrong resolution get silently reused. A private dir has neither.
    try {
      await _foreground.show(label, text: 'Starting…');
      final workDir = await _createTempDirectory();
      tmpDir = workDir;

      // 1. Download the selected stream (with one network-rebind retry on NETWORK
      // error — a mid-download Wi-Fi ↔ cellular switch kills Python's bound
      // socket; rebinding the process picks up the new network).
      final primary = await _downloadFormatWithNetworkRetry(
        operation.url,
        fmt,
        workDir.path,
        onProgress: (received, total) {
          if (_shouldStop(operation)) return;
          state = Downloading(format: fmt, received: received, total: total);
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
        },
      );
      temps.add(primary);
      if (_shouldStop(operation)) return;

      // 2. Post-process: merge video-only with audio, or transcode audio to MP3.
      final String finalPath;
      final String ext;
      final String mime;
      if (fmt.needsMerge) {
        final audioFmt = _bestAudio(info);
        if (audioFmt == null) {
          throw const ApiException(
            code: ApiErrorCode.unknown,
            message: 'No audio track available to merge.',
          );
        }
        final audioPath = await _downloadFormatWithNetworkRetry(
          operation.url,
          audioFmt,
          workDir.path,
        );
        temps.add(audioPath);
        if (_shouldStop(operation)) return;
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
        final cover = await _cover.fetch(info.thumbnail, workDir.path);
        if (cover != null) temps.add(cover);
        finalPath = await _processor.toMp3(
          primary,
          coverPath: cover,
          title: info.title,
          artist: info.uploader,
        );
        temps.add(finalPath);
        ext = 'mp3';
        mime = 'audio/mpeg';
      } else {
        finalPath = primary; // muxed video+audio — ready as-is
        ext = fmt.ext ?? 'mp4';
        mime = _videoMime(ext);
      }
      if (_shouldStop(operation)) return;

      // 3. Save to public Downloads. Its own phase: copying 1.3 GB into MediaStore
      // is slow enough that a stalled "Merging" would read as a hang.
      await _foreground.show(label, text: 'Saving to Downloads');
      final saved = await _storage.saveToDownloads(
        File(finalPath),
        fileName: _fileName(info.title, ext),
        mimeType: mime,
      );
      if (_shouldStop(operation)) return;
      if (!saved.isSuccess) {
        final message = saved.message ?? 'Could not save the file.';
        state = Failed(ApiErrorCode.unknown, message);
        outcome = (
          title: describeError(ApiErrorCode.unknown),
          text: message,
          uri: null,
          mime: null,
        );
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
      await _recordHistory(info, operation.url, stored, fmt, bytes);
      outcome = (
        title: label,
        text: 'Saved to Downloads · tap to open',
        uri: saved.uri,
        mime: mime,
      );
      state = Done(path: saved.path ?? stored, uri: saved.uri);
    } on ApiException catch (e) {
      if (!_shouldStop(operation)) {
        state = Failed(e.code, e.message);
        outcome = (
          title: describeError(e.code),
          text: e.message,
          uri: null,
          mime: null,
        );
      }
    } catch (error, stackTrace) {
      if (!_shouldStop(operation)) {
        _logUnexpected('download', error, stackTrace);
        final message = _unexpectedDownloadMessage(error);
        state = Failed(ApiErrorCode.unknown, message);
        outcome = (
          title: describeError(ApiErrorCode.unknown),
          text: message,
          uri: null,
          mime: null,
        );
      }
    } finally {
      for (final p in temps) {
        await _deleteQuietly(p);
      }
      if (tmpDir != null) {
        await _deleteDirQuietly(tmpDir); // nuke .part files and fragments
      }
      // Release the process last: cleanup is part of the download too. The result
      // has to be posted *after*, because stopping the service takes its own
      // notification down with it.
      await _runCleanupStep('hide foreground notification', _foreground.hide);
      // Nothing to say after a cancel — the user did that themselves.
      if (outcome != null) {
        final result = outcome;
        await _runCleanupStep(
          'show download result',
          () => _foreground.showResult(
            result.title,
            result.text,
            uri: result.uri,
            mimeType: result.mime,
          ),
        );
      }
      if (identical(_activeDownload, operation)) {
        _activeDownload = null;
        if (operation.cancelled) {
          state = FormatsReady(operation.info, selected: operation.format);
        }
      }
    }
  }

  /// Download one [format] into [dir] (a private scratch dir) via yt-dlp.
  Future<String> _downloadFormat(
    String url,
    MediaFormat format,
    String dir, {
    void Function(int received, int total)? onProgress,
  }) => _ytdlp.download(url, format.formatId, onProgress: onProgress, dir: dir);

  /// Wrapper around [_downloadFormat] that retries once after rebinding the
  /// process network if yt-dlp returns a NETWORK error (mid-download Wi-Fi ↔
  /// cellular switch). yt-dlp binds the socket to the active network at start;
  /// a switch invalidates it. Rebinding the process picks up the new network,
  /// then the same format is re-requested.
  Future<String> _downloadFormatWithNetworkRetry(
    String url,
    MediaFormat format,
    String dir, {
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      return await _downloadFormat(url, format, dir, onProgress: onProgress);
    } on ApiException catch (e) {
      if (e.code != ApiErrorCode.network) rethrow;
      // One shot: rebind, then retry the exact same download.
      await _ytdlp.rebindNetwork();
      return await _downloadFormat(url, format, dir, onProgress: onProgress);
    }
  }

  bool _shouldStop(_DownloadOperation operation) =>
      operation.cancelled || !identical(_activeDownload, operation);

  Future<void> _runCleanupStep(
    String step,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (error, stackTrace) {
      _logUnexpected(step, error, stackTrace);
    }
  }

  String _unexpectedExtractMessage(Object error) => error is FormatException
      ? 'The media extractor returned an invalid response. Please try again.'
      : 'Could not inspect this link. Please try again.';

  String _unexpectedDownloadMessage(Object error) =>
      error is FileSystemException
      ? 'Could not access temporary storage. Check free space and try again.'
      : 'The download could not be completed. Please try again.';

  void _logUnexpected(String phase, Object error, StackTrace stackTrace) {
    developer.log(
      'Unexpected $phase failure',
      name: 'woofer.download',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Best audio-only format to pair with a video-only stream.
  ///
  /// yt-dlp's filesize is frequently unknown for adaptive formats (it requires a
  /// range probe), so ranking by size alone picks arbitrarily. Instead we prefer,
  /// in order: (1) a codec compatible with the video's container so the merge
  /// stays a cheap stream-copy into mp4/webm rather than falling back to mkv,
  /// (2) the highest audio bitrate, (3) highest sample rate, (4) most channels,
  /// (5) preferred codec (opus > aac), (6) largest filesize as a final tiebreak.
  MediaFormat? _bestAudio(VideoInfo info) {
    final audios = info.formats
        .where((f) => f.hasAudio && !f.hasVideo)
        .toList();
    if (audios.isEmpty) return null;

    // The video format we'll merge with — used to prefer a compatible codec.
    final videoFmt = _selected;

    int compare(MediaFormat a, MediaFormat b) {
      // Compatible codec first: a compatible audio format outranks an
      // incompatible one even at lower bitrate, because it avoids an mkv
      // fallback that some players dislike.
      final aCompat = videoFmt == null ? true : _isAudioCompatible(videoFmt, a);
      final bCompat = videoFmt == null ? true : _isAudioCompatible(videoFmt, b);
      if (aCompat != bCompat) return aCompat ? -1 : 1;

      // Bitrate: the primary quality signal for audio.
      final ab = _audioBitrate(a);
      final bb = _audioBitrate(b);
      final bitrateCmp = (bb ?? 0).compareTo(ab ?? 0);
      if (bitrateCmp != 0) return bitrateCmp;

      // Sample rate: higher is better (48kHz > 44.1kHz).
      final aSr = a.sampleRate ?? 0;
      final bSr = b.sampleRate ?? 0;
      final srCmp = bSr.compareTo(aSr);
      if (srCmp != 0) return srCmp;

      // Channel count: more channels = richer audio (surround > stereo > mono).
      final aCh = a.audioChannels ?? 0;
      final bCh = b.audioChannels ?? 0;
      final chCmp = bCh.compareTo(aCh);
      if (chCmp != 0) return chCmp;

      // Audio codec preference: opus is generally better than aac at same bitrate.
      final aCodecPref = _audioCodecPreference(a.audioCodec);
      final bCodecPref = _audioCodecPreference(b.audioCodec);
      final codecCmp = bCodecPref.compareTo(aCodecPref);
      if (codecCmp != 0) return codecCmp;

      // Filesize as a final tiebreaker when all else matches.
      return (b.filesize ?? 0).compareTo(a.filesize ?? 0);
    }

    audios.sort(compare);
    return audios.first;
  }

  /// Numeric preference for audio codecs (higher = preferred).
  /// Opus generally provides better quality than AAC at equivalent bitrates.
  static int _audioCodecPreference(String? codec) {
    final c = codec?.toLowerCase();
    if (c == null || c.isEmpty) return 0;
    if (c.contains('opus')) return 3;
    if (c.contains('aac') || c.contains('mp4a')) return 2;
    if (c.contains('vorbis') || c.contains('ogg')) return 1;
    return 0;
  }

  /// Whether [audio] is a codec/extension family that stream-copies into the
  /// same container family as [video] (avoiding an mkv fallback).
  static bool _isAudioCompatible(MediaFormat video, MediaFormat audio) {
    final v = (video.ext ?? '').toLowerCase();
    final a = (audio.ext ?? '').toLowerCase();
    const mp4V = {'mp4', 'm4v', 'mov'};
    const mp4A = {'m4a', 'mp4', 'aac'};
    if (mp4V.contains(v) && mp4A.contains(a)) return true;
    if (v == 'webm' && {'webm', 'opus', 'ogg'}.contains(a)) return true;
    return false;
  }

  /// Effective audio bitrate, falling back to total bitrate when the stream is
  /// audio-only (no separate video bitrate to subtract).
  static double? _audioBitrate(MediaFormat f) =>
      f.audioBitrate ?? f.totalBitrate;

  Future<void> _recordHistory(
    VideoInfo info,
    String url,
    String path,
    MediaFormat format,
    int? size,
  ) async {
    try {
      final history = await ref.read(historyServiceProvider.future);
      await history.add(
        HistoryEntry(
          title: info.title,
          thumbnail: info.thumbnail,
          sourceUrl: url,
          filePath: path,
          format: format.resolution ?? format.note ?? format.formatId,
          size: size,
        ),
      );
      ref.invalidate(historyListProvider); // the Library tab picks it up
    } catch (_) {
      // ponytail: history is best-effort — logging failure must not fail a saved download.
    }
  }

  String _fileName(String? title, String ext) => safeMediaFileName(title, ext);

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

/// Immutable inputs and mutable cancellation ownership for one pipeline.
/// Identity, rather than controller-wide booleans, keeps stale callbacks from
/// affecting any operation which may follow it.
class _DownloadOperation {
  final String url;
  final VideoInfo info;
  final MediaFormat format;
  bool cancelled = false;

  _DownloadOperation({
    required this.url,
    required this.info,
    required this.format,
  });
}
