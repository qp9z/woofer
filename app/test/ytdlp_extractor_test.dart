import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woofer/services/api_exception.dart';
import 'package:woofer/services/ytdlp_extractor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('ytdlp_test');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  /// Make the mocked native side answer [method] with [reply] (a JSON string),
  /// or throw [error] if given.
  void mockChannel({String? reply, PlatformException? error, void Function(MethodCall)? spy}) {
    messenger.setMockMethodCallHandler(channel, (call) async {
      spy?.call(call);
      if (error != null) throw error;
      return reply;
    });
  }

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  YtdlpExtractor extractor() => YtdlpExtractor(channel: channel);

  group('extractInfo', () {
    test('parses a success envelope into the shared VideoInfo model', () async {
      mockChannel(
        reply: jsonEncode({
          'ok': true,
          'data': {
            'title': 'Clip',
            'thumbnail': 'http://t/x.jpg',
            'duration': 187,
            'uploader': 'Someone',
            'formats': [
              {
                'format_id': '137',
                'ext': 'mp4',
                'resolution': '1080p',
                'filesize': 5000000,
                'has_audio': false,
                'has_video': true,
                'note': '1080p',
              },
              {
                'format_id': '140',
                'ext': 'm4a',
                'has_audio': true,
                'has_video': false,
              },
            ],
          },
        }),
      );

      final info = await extractor().extractInfo('http://y/x');

      expect(info.title, 'Clip');
      expect(info.uploader, 'Someone');
      expect(info.duration, 187);
      expect(info.formats, hasLength(2));
      // The video-only format is flagged for merge; the audio-only one is not.
      expect(info.formats.first.needsMerge, isTrue);
      expect(info.formats.last.hasAudio, isTrue);
      expect(info.formats.last.needsMerge, isFalse);
    });

    test('an error envelope becomes a mapped ApiException', () async {
      mockChannel(reply: jsonEncode({'ok': false, 'code': 'PRIVATE', 'message': 'This video is private'}));

      expect(
        () => extractor().extractInfo('http://y/x'),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', ApiErrorCode.private)
            .having((e) => e.message, 'message', 'This video is private')),
      );
    });

    test('a PlatformException is mapped by its code', () async {
      mockChannel(error: PlatformException(code: 'RATE_LIMITED', message: 'slow down'));

      expect(
        () => extractor().extractInfo('http://y/x'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', ApiErrorCode.rateLimited)),
      );
    });

    test('a missing native plugin surfaces as unknown, not a crash', () async {
      messenger.setMockMethodCallHandler(channel, null); // no handler → MissingPluginException
      expect(
        () => extractor().extractInfo('http://y/x'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', ApiErrorCode.unknown)),
      );
    });
  });

  group('download', () {
    test('returns the saved path from a success envelope', () async {
      MethodCall? seen;
      mockChannel(reply: jsonEncode({'ok': true, 'path': '/tmp/woofer/Clip.mp4'}), spy: (c) => seen = c);

      final path = await extractor().download('http://y/x', '137', dir: '/tmp/woofer');

      expect(path, '/tmp/woofer/Clip.mp4');
      expect(seen?.method, 'download');
      expect((seen?.arguments as Map)['format_id'], '137');
      expect((seen?.arguments as Map)['dir'], '/tmp/woofer');
    });

    test('a download error envelope maps to its code', () async {
      mockChannel(reply: jsonEncode({'ok': false, 'code': 'GEO', 'message': 'blocked in your country'}));
      expect(
        () => extractor().download('http://y/x', '137'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', ApiErrorCode.unavailable)),
      );
    });

    test('native onProgress pings reach the callback during the download', () async {
      // Keep the download pending so the active callback is still wired up while
      // the native side pushes progress (as it does mid-transfer in reality).
      final reply = Completer<String>();
      messenger.setMockMethodCallHandler(
          channel, (call) async => call.method == 'download' ? reply.future : null);

      // Deliver an incoming onProgress call from the "native" side.
      Future<void> pushProgress(int r, int t) => messenger.handlePlatformMessage(
            channel.name,
            channel.codec.encodeMethodCall(MethodCall('onProgress', {'received': r, 'total': t})),
            (_) {},
          );

      final seen = <List<int>>[];
      final done = extractor().download('http://y/x', '137', onProgress: (r, t) => seen.add([r, t]));

      await pushProgress(512, 1024);
      await pushProgress(1024, 1024);
      reply.complete(jsonEncode({'ok': true, 'path': '/x.mp4'}));

      expect(await done, '/x.mp4');
      expect(seen, [
        [512, 1024],
        [1024, 1024],
      ]);
    });
  });

  group('ytdlpErrorCode', () {
    test('reuses the backend wire vocabulary', () {
      expect(ytdlpErrorCode('PRIVATE'), ApiErrorCode.private);
      expect(ytdlpErrorCode('UNSUPPORTED'), ApiErrorCode.unsupported);
      expect(ytdlpErrorCode('INVALID_URL'), ApiErrorCode.invalidUrl);
      expect(ytdlpErrorCode('TOO_LARGE'), ApiErrorCode.tooLarge);
    });
    test('handles the on-device-only tokens', () {
      expect(ytdlpErrorCode('NETWORK'), ApiErrorCode.network);
      expect(ytdlpErrorCode('GEO'), ApiErrorCode.unavailable);
    });
    test('anything unrecognized is unknown', () {
      expect(ytdlpErrorCode('WAT'), ApiErrorCode.unknown);
      expect(ytdlpErrorCode(null), ApiErrorCode.unknown);
    });
  });
}
