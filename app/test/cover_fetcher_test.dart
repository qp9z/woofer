import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:woofer/services/cover_fetcher.dart';

/// Serves canned responses for the tests and teardowns itself.
class _ArtServer {
  _ArtServer({
    required this.status,
    required this.contentType,
    required this.body,
  });

  final int status;
  final String? contentType;
  final List<int> body;

  late HttpServer server;
  Uri? uri;

  Future<void> start() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    uri = Uri.parse('http://${server.address.address}:${server.port}/thumb.webp');
    server.listen((request) {
      request.response.statusCode = status;
      if (contentType != null) {
        request.response.headers.contentType = ContentType.parse(contentType!);
      }
      request.response.add(body);
      request.response.close();
    });
  }

  Future<void> stop() async => server.close(force: true);
}

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('woofer_cover'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<_ArtServer> serve({
    int status = 200,
    String? contentType = 'image/webp',
    List<int> body = const [1, 2, 3, 4],
  }) async {
    final s = _ArtServer(status: status, contentType: contentType, body: body);
    await s.start();
    addTearDown(s.stop);
    return s;
  }

  test('downloads an image and returns its path', () async {
    final s = await serve();
    final path = await const CoverFetcher().fetch(s.uri!.toString(), dir.path);

    expect(path, isNotNull);
    expect(File(path!).lengthSync(), 4);
  });

  test('rejects a clearly non-image content type', () async {
    final s = await serve(contentType: 'text/html', body: [60, 104, 116, 109, 108, 62] /* <html> */);
    expect(await const CoverFetcher().fetch(s.uri!.toString(), dir.path), isNull);
    expect(dir.listSync(), isEmpty); // nothing written
  });

  test('allows octet-stream which wraps webp from some CDNs', () async {
    final s = await serve(contentType: 'application/octet-stream', body: [9, 8, 7]);
    expect(await const CoverFetcher().fetch(s.uri!.toString(), dir.path), isNotNull);
  });

  test('rejects an oversized response and leaves no file', () async {
    // 20 bytes body but a 10-byte cap => must be dropped.
    final s = await serve(body: List.filled(20, 1));
    final path = await CoverFetcher(maxBytes: 10).fetch(s.uri!.toString(), dir.path);

    expect(path, isNull);
    expect(dir.listSync(), isEmpty);
  });

  test('treats a non-200 status as no artwork', () async {
    final s = await serve(status: 404);
    expect(await const CoverFetcher().fetch(s.uri!.toString(), dir.path), isNull);
  });

  test('null, empty, and non-http URLs return null', () async {
    const fetcher = CoverFetcher();
    expect(await fetcher.fetch(null, dir.path), isNull);
    expect(await fetcher.fetch('', dir.path), isNull);
    expect(await fetcher.fetch('ftp://example.com/t', dir.path), isNull);
    expect(await fetcher.fetch('not a url', dir.path), isNull);
  });
}