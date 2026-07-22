import 'dart:io';

import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/media_format.dart';
import '../models/video_info.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';
import '../services/history_service.dart';
import '../services/storage_service.dart';
import 'download_state.dart';

/// Injectable services — override these in tests.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final storageServiceProvider = Provider<StorageService>((ref) => StorageService());
final historyServiceProvider = FutureProvider<HistoryService>((ref) => HistoryService.open());

/// Past downloads, newest first. Invalidated whenever a download is recorded.
final historyListProvider = FutureProvider<List<HistoryEntry>>((ref) async {
  final history = await ref.watch(historyServiceProvider.future);
  return history.getAll();
});

/// The one entry point for the download flow. Drives [DownloadState] through
/// idle → loading → formatsReady → downloading → done | error.
final downloadControllerProvider =
    NotifierProvider<DownloadController, DownloadState>(DownloadController.new);

class DownloadController extends Notifier<DownloadState> {
  String? _url;
  CancelToken? _cancelToken;
  bool _cancelled = false;

  @override
  DownloadState build() => const Idle();

  ApiClient get _api => ref.read(apiClientProvider);
  StorageService get _storage => ref.read(storageServiceProvider);

  /// Resolve [url] to formats. Moves to [FormatsReady] or [Failed].
  Future<void> extract(String url) async {
    _url = url;
    state = const Loading();
    try {
      final info = await _api.extract(url);
      state = FormatsReady(info);
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
    state = const Idle();
  }

  /// Abort an in-flight download: kills the HTTP stream, drops the partial
  /// file, and returns to format selection (not an error state).
  void cancel() {
    _cancelled = true;
    _cancelToken?.cancel('cancelled by user');
  }

  /// Download the selected format, save it to Downloads, and record history.
  /// No-op unless a format is selected in [FormatsReady].
  Future<void> download() async {
    final ready = state;
    if (ready is! FormatsReady) return;
    final format = ready.selected;
    final url = _url;
    if (format == null || url == null) return;

    final info = ready.info;
    final mode = format.hasVideo ? 'video' : 'audio';
    // Audio-only is transcoded to mp3 by the backend; video stays as its container.
    final ext = mode == 'audio' ? 'mp3' : (format.ext ?? 'mp4');
    final mime = mode == 'audio' ? 'audio/mpeg' : 'video/mp4';

    state = Downloading(format: format, received: 0, total: format.filesize ?? -1);

    _cancelled = false;
    final token = CancelToken();
    _cancelToken = token;

    final tmp = File(
        '${Directory.systemTemp.path}/woofer_${DateTime.now().millisecondsSinceEpoch}.$ext');
    try {
      await _api.download(
        url,
        format.formatId,
        mode,
        savePath: tmp.path,
        cancelToken: token,
        onProgress: (received, total) {
          state = Downloading(format: format, received: received, total: total);
        },
      );

      final saved = await _storage.saveToDownloads(
        tmp,
        fileName: _fileName(info.title, ext),
        mimeType: mime,
      );
      await _deleteQuietly(tmp);

      if (!saved.isSuccess) {
        state = Failed(ApiErrorCode.unknown, saved.message ?? 'Could not save the file.');
        return;
      }

      final path = saved.path ?? saved.uri ?? tmp.path;
      await _recordHistory(info, url, path, format);
      state = Done(path: path, uri: saved.uri);
    } on ApiException catch (e) {
      await _deleteQuietly(tmp);
      // A cancel surfaces as a stream error — that's a user action, not a failure.
      state = _cancelled ? FormatsReady(info, selected: format) : Failed(e.code, e.message);
    } finally {
      _cancelToken = null;
    }
  }

  Future<void> _recordHistory(
      VideoInfo info, String url, String path, MediaFormat format) async {
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

  Future<void> _deleteQuietly(File f) async {
    try {
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}
