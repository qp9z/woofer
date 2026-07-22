import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/media_format.dart';
import '../services/api_exception.dart';
import '../services/history_service.dart';
import '../services/storage_service.dart';
import 'download_state.dart';

/// Injectable services — override these in tests.
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
  // ignore: unused_field
  String? _url;

  @override
  DownloadState build() => const Idle();

  /// Resolve [url] to formats. Moves to [FormatsReady] or [Failed].
  ///
  // ponytail: STUB — the network backend is gone. Wire this to the on-device
  // extractor next; until then it fails cleanly so the UI stays honest.
  Future<void> extract(String url) async {
    _url = url;
    state = const Loading();
    state = const Failed(ApiErrorCode.unknown, 'On-device extraction not wired yet.');
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

  /// Abort an in-flight download and return to format selection.
  // ponytail: STUB — no-op; nothing is in flight until download() does real work.
  void cancel() {}

  /// Download the selected format. No-op unless a format is selected.
  ///
  // ponytail: STUB — wire to the on-device saver next.
  Future<void> download() async {
    final ready = state;
    if (ready is! FormatsReady || ready.selected == null) return;
    state = const Failed(ApiErrorCode.unknown, 'On-device download not wired yet.');
  }
}
