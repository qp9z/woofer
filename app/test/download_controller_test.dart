import 'dart:io';

import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:woofer/models/media_format.dart';
import 'package:woofer/models/video_info.dart';
import 'package:woofer/services/api_client.dart';
import 'package:woofer/services/api_exception.dart';
import 'package:woofer/services/history_service.dart';
import 'package:woofer/services/storage_service.dart';
import 'package:woofer/state/download_controller.dart';
import 'package:woofer/state/download_state.dart';

const _audio = MediaFormat(formatId: '140', ext: 'm4a', hasAudio: true, hasVideo: false);
const _video =
    MediaFormat(formatId: '137', ext: 'mp4', resolution: '1080p', filesize: 1024, hasAudio: false, hasVideo: true);

/// Canned API. [extractError] makes extract throw; otherwise download writes a
/// stub file to savePath and pings progress so the state machine advances.
class _FakeApi extends ApiClient {
  _FakeApi({this.extractError});
  final ApiException? extractError;
  String? lastMode;

  @override
  Future<VideoInfo> extract(String url) async {
    if (extractError != null) throw extractError!;
    return const VideoInfo(title: 'Clip', thumbnail: 'http://t/x.jpg', formats: [_video, _audio]);
  }

  @override
  Future<File> download(String url, String formatId, String mode,
      {required String savePath,
      ProgressCallback? onProgress,
      CancelToken? cancelToken}) async {
    lastMode = mode;
    onProgress?.call(512, 1024);
    await Future<void>.delayed(Duration.zero); // let a cancel land mid-transfer
    // Mirror dio: a cancelled token aborts the transfer with an error.
    if (cancelToken?.isCancelled ?? false) {
      throw const ApiException(code: ApiErrorCode.network, message: 'cancelled');
    }
    final f = File(savePath)..writeAsStringSync('data');
    onProgress?.call(1024, 1024);
    return f;
  }
}

class _FakeStorage extends StorageService {
  _FakeStorage({this.result = const StorageResult(StorageStatus.success, path: '/Download/woofer/Clip.mp4')});
  final StorageResult result;

  @override
  Future<StorageResult> saveToDownloads(File source, {String? fileName, String mimeType = 'application/octet-stream'}) async =>
      result;
}

ProviderContainer _container(_FakeApi api, StorageService storage, HistoryService history) => ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(api),
        storageServiceProvider.overrideWithValue(storage),
        historyServiceProvider.overrideWith((ref) async => history),
      ],
    );

void main() {
  late HistoryService history;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // singleInstance:false so each test gets a distinct :memory: db (default
    // caches by path, and all in-memory dbs share the ":memory:" path).
    final db = await databaseFactory.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(singleInstance: false));
    history = HistoryService(db);
    await history.init();
  });

  test('idle → formatsReady on extract', () async {
    final c = _container(_FakeApi(), _FakeStorage(), history);
    addTearDown(c.dispose);
    final ctrl = c.read(downloadControllerProvider.notifier);

    expect(c.read(downloadControllerProvider), isA<Idle>());
    await ctrl.extract('http://y/x');

    final s = c.read(downloadControllerProvider);
    expect(s, isA<FormatsReady>());
    expect((s as FormatsReady).formats, hasLength(2));
  });

  test('extract failure surfaces the error code', () async {
    final api = _FakeApi(extractError: const ApiException(code: ApiErrorCode.private, message: 'private'));
    final c = _container(api, _FakeStorage(), history);
    addTearDown(c.dispose);

    await c.read(downloadControllerProvider.notifier).extract('http://y/x');

    final s = c.read(downloadControllerProvider);
    expect(s, isA<Failed>());
    expect((s as Failed).code, ApiErrorCode.private);
  });

  test('full flow: download → done + history recorded', () async {
    final api = _FakeApi();
    final c = _container(api, _FakeStorage(), history);
    addTearDown(c.dispose);
    final ctrl = c.read(downloadControllerProvider.notifier);

    await ctrl.extract('http://y/x');
    ctrl.selectFormat(_video);
    expect((c.read(downloadControllerProvider) as FormatsReady).selected, _video);

    await ctrl.download();

    final s = c.read(downloadControllerProvider);
    expect(s, isA<Done>());
    expect((s as Done).path, '/Download/woofer/Clip.mp4');
    expect(api.lastMode, 'video'); // hasVideo → "video"

    final rows = await history.getAll();
    expect(rows, hasLength(1));
    expect(rows.single.sourceUrl, 'http://y/x');
    expect(rows.single.filePath, '/Download/woofer/Clip.mp4');
  });

  test('audio-only format downloads in audio mode', () async {
    final api = _FakeApi();
    final c = _container(api, _FakeStorage(), history);
    addTearDown(c.dispose);
    final ctrl = c.read(downloadControllerProvider.notifier);

    await ctrl.extract('http://y/x');
    ctrl.selectFormat(_audio);
    await ctrl.download();

    expect(c.read(downloadControllerProvider), isA<Done>());
    expect(api.lastMode, 'audio');
  });

  test('cancel aborts the transfer and returns to format selection', () async {
    final c = _container(_FakeApi(), _FakeStorage(), history);
    addTearDown(c.dispose);
    final ctrl = c.read(downloadControllerProvider.notifier);

    await ctrl.extract('http://y/x');
    ctrl.selectFormat(_video);

    final pending = ctrl.download();
    ctrl.cancel();
    await pending;

    // A cancel is a user action, not a Failed state.
    final s = c.read(downloadControllerProvider);
    expect(s, isA<FormatsReady>());
    expect((s as FormatsReady).selected, _video);
    expect(await history.getAll(), isEmpty);
  });

  test('save failure → error(unknown)', () async {
    final storage = _FakeStorage(result: const StorageResult(StorageStatus.permissionDenied, message: 'denied'));
    final c = _container(_FakeApi(), storage, history);
    addTearDown(c.dispose);
    final ctrl = c.read(downloadControllerProvider.notifier);

    await ctrl.extract('http://y/x');
    ctrl.selectFormat(_video);
    await ctrl.download();

    final s = c.read(downloadControllerProvider);
    expect(s, isA<Failed>());
    expect((s as Failed).code, ApiErrorCode.unknown);
    expect((await history.getAll()), isEmpty);
  });
}
