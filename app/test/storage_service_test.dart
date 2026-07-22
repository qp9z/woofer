import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woofer/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('woofer/storage');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late File tmp;

  setUp(() async {
    tmp = File('${Directory.systemTemp.path}/woofer_test_src.bin');
    await tmp.writeAsBytes([1, 2, 3]);
  });

  tearDown(() async {
    messenger.setMockMethodCallHandler(channel, null);
    if (await tmp.exists()) await tmp.delete();
  });

  test('saveToDownloads returns success with path + uri', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'saveToDownloads');
      expect(call.arguments['subDir'], 'woofer');
      expect(call.arguments['fileName'], 'x.bin');
      return {'uri': 'content://media/downloads/42', 'path': 'Download/woofer/x.bin'};
    });
    final svc = StorageService(permissionGate: () async => null); // granted
    final res = await svc.saveToDownloads(tmp, fileName: 'x.bin');
    expect(res.isSuccess, isTrue);
    expect(res.uri, 'content://media/downloads/42');
    expect(res.path, 'Download/woofer/x.bin');
  });

  test('permission denied is a typed result and skips the channel', () async {
    var called = false;
    messenger.setMockMethodCallHandler(channel, (call) async {
      called = true;
      return null;
    });
    final svc = StorageService(
      permissionGate: () async =>
          const StorageResult(StorageStatus.permissionDenied, message: 'nope'),
    );
    final res = await svc.saveToDownloads(tmp, fileName: 'x.bin');
    expect(res.status, StorageStatus.permissionDenied);
    expect(called, isFalse);
  });

  test('platform error becomes a failed result, never throws', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'IO', message: 'disk full');
    });
    final svc = StorageService(permissionGate: () async => null);
    final res = await svc.saveToDownloads(tmp, fileName: 'x.bin');
    expect(res.status, StorageStatus.failed);
    expect(res.message, contains('disk full'));
  });

  test('missing source file fails before any channel call', () async {
    var called = false;
    messenger.setMockMethodCallHandler(channel, (call) async {
      called = true;
      return null;
    });
    final svc = StorageService(permissionGate: () async => null);
    final res = await svc.saveToDownloads(File('/no/such/file.bin'));
    expect(res.status, StorageStatus.failed);
    expect(called, isFalse);
  });

  test('openFile returns channel bool; shareFile swallows errors', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'openFile') return true;
      if (call.method == 'shareFile') throw PlatformException(code: 'x');
      return null;
    });
    final svc = StorageService();
    expect(await svc.openFile('content://media/downloads/42'), isTrue);
    expect(await svc.shareFile('/storage/emulated/0/Download/woofer/x.bin'), isFalse);
  });
}
