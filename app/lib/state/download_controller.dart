import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/media_format.dart';
import '../models/video_info.dart';
import '../services/api_exception.dart';
import '../services/history_service.dart';
import '../services/media_processor.dart';
import '../services/storage_service.dart';
import '../services/ytdlp_extractor.dart';
import 'download_state.dart';

/// Injectable services — override these in tests. Everything runs on-device;
/// yt-dlp (Chaquopy) is the single extractor for every site, YouTube included.
final ytdlpExtractorProvider = Provider<YtdlpExtractor>((ref) => YtdlpExtractor());
final mediaProcessorProvider = Provider<MediaProcessor>((ref) => MediaProcessor());
final storageServiceProvider = Provider<StorageService>((ref) => StorageService());
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
  DownloadState build() => const Idle();

  YtdlpExtractor get _ytdlp => ref.read(ytdlpExtractorProvider);
  MediaProcessor get _processor => ref.read(mediaProcessorProvider);
  StorageService get _storage => ref.read(storageServiceProvider);

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

  /// Back to a clean slate.
  void reset() {
    _url = null;
    _info = null;
    _selected = null;
    state = const Idle();
  }

  /// Abort the flow and return to format selection. A real mid-stream abort
  /// isn't available for the on-device extractor, so this is a soft cancel:
  /// the pipeline checks [_cancelled] at each step, stops before saving, and
  /// discards its temp files.
  // ponytail: soft cancel — an in-flight network read finishes into a temp that
  // then gets deleted, rather than being killed instantly. Wire a real abort
  // (a native yt-dlp cancel / FFmpegKit.cancel) if that matters.
  void cancel() {
    _cancelled = true;
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

    state = Downloading(format: fmt, received: 0, total: fmt.filesize ?? -1);
    try {
      // 1. Download the selected stream.
      final primary = await _downloadFormat(fmt, onProgress: (received, total) {
        if (!_cancelled) state = Downloading(format: fmt, received: received, total: total);
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
        final audioPath = await _downloadFormat(audioFmt);
        temps.add(audioPath);
        if (_cancelled) return;
        state = Processing(fmt, 'Merging video and audio');
        finalPath = await _processor.mergeVideoAudio(primary, audioPath);
        temps.add(finalPath);
        ext = 'mp4';
        mime = 'video/mp4';
      } else if (!fmt.hasVideo) {
        state = Processing(fmt, 'Converting to MP3');
        finalPath = await _processor.toMp3(primary, 192);
        temps.add(finalPath);
        ext = 'mp3';
        mime = 'audio/mpeg';
      } else {
        finalPath = primary; // muxed video+audio — ready as-is
        ext = fmt.ext ?? 'mp4';
        mime = 'video/mp4';
      }
      if (_cancelled) return;

      // 3. Save to public Downloads.
      final saved = await _storage.saveToDownloads(
        File(finalPath),
        fileName: _fileName(info.title, ext),
        mimeType: mime,
      );
      if (_cancelled) return;
      if (!saved.isSuccess) {
        state = Failed(ApiErrorCode.unknown, saved.message ?? 'Could not save the file.');
        return;
      }

      // 4. Record history.
      final path = saved.path ?? saved.uri ?? finalPath;
      await _recordHistory(info, url, path, fmt);
      state = Done(path: path, uri: saved.uri);
    } on ApiException catch (e) {
      if (!_cancelled) state = Failed(e.code, e.message);
    } finally {
      for (final p in temps) {
        await _deleteQuietly(p);
      }
    }
  }

  /// Download one [format] to a temp file via yt-dlp.
  Future<String> _downloadFormat(
    MediaFormat format, {
    void Function(int received, int total)? onProgress,
  }) =>
      _ytdlp.download(_url!, format.formatId, onProgress: onProgress, dir: Directory.systemTemp.path);

  /// Best audio-only format to pair with a video-only stream (largest = best).
  MediaFormat? _bestAudio(VideoInfo info) {
    final audios = info.formats.where((f) => f.hasAudio && !f.hasVideo).toList();
    if (audios.isEmpty) return null;
    audios.sort((a, b) => (b.filesize ?? 0).compareTo(a.filesize ?? 0));
    return audios.first;
  }

  Future<void> _recordHistory(VideoInfo info, String url, String path, MediaFormat format) async {
    try {
      final history = await ref.read(historyServiceProvider.future);
      await history.add(HistoryEntry(
        title: info.title,
        thumbnail: info.thumbnail,
        sourceUrl: url,
        filePath: path,
        format: format.resolution ?? format.note ?? format.formatId,
        size: format.filesize,
      ));
      ref.invalidate(historyListProvider); // HistoryScreen picks it up
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
}
