import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:woofer/models/media_format.dart';
import 'package:woofer/services/api_exception.dart';
import 'package:woofer/services/youtube_extractor.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() {
  group('MediaFormat.needsMerge', () {
    test('video-only needs a merge', () {
      const f = MediaFormat(formatId: '137', hasVideo: true, hasAudio: false);
      expect(f.needsMerge, isTrue);
    });
    test('muxed (video+audio) does not', () {
      const f = MediaFormat(formatId: '18', hasVideo: true, hasAudio: true);
      expect(f.needsMerge, isFalse);
    });
    test('audio-only does not', () {
      const f = MediaFormat(formatId: '140', hasVideo: false, hasAudio: true);
      expect(f.needsMerge, isFalse);
    });
  });

  group('mapYoutubeError', () {
    ApiErrorCode codeOf(Object e) => mapYoutubeError(e).code;

    test('unparseable link → invalidUrl', () {
      expect(codeOf(ArgumentError.value('nope', 'url')), ApiErrorCode.invalidUrl);
    });
    test('rate limit → rateLimited', () {
      expect(codeOf(RequestLimitExceededException('slow down')), ApiErrorCode.rateLimited);
    });
    test('unavailable / private / removed → unavailable', () {
      expect(codeOf(VideoUnavailableException('gone')), ApiErrorCode.unavailable);
    });
    test('unplayable (restricted, live) → unavailable', () {
      expect(codeOf(VideoUnplayableException('restricted')), ApiErrorCode.unavailable);
    });
    test('transient/fatal request failure → network', () {
      expect(codeOf(TransientFailureException('flaky')), ApiErrorCode.network);
      expect(codeOf(FatalFailureException('boom', 500)), ApiErrorCode.network);
    });
    test('socket/timeout → network', () {
      expect(codeOf(const SocketException('no route')), ApiErrorCode.network);
      expect(codeOf(TimeoutException('slow')), ApiErrorCode.network);
    });
    test('unknown youtube error → unknown, keeps message', () {
      final mapped = mapYoutubeError(HttpClientClosedException());
      expect(mapped.code, ApiErrorCode.unknown);
      expect(mapped.message, isNotEmpty);
    });
    test('an ApiException passes straight through', () {
      const original = ApiException(code: ApiErrorCode.tooLarge, message: 'x');
      expect(identical(mapYoutubeError(original), original), isTrue);
    });
  });

  group('writeStreamToFile', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('woofer_test'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('writes all bytes and reports progress to total', () async {
      final dest = File('${dir.path}/out.bin');
      final chunks = [
        [1, 2, 3],
        [4, 5],
        [6, 7, 8, 9],
      ];
      final progress = <List<int>>[];
      await writeStreamToFile(
        Stream.fromIterable(chunks),
        9,
        dest,
        (received, total) => progress.add([received, total]),
      );

      expect(dest.readAsBytesSync(), [1, 2, 3, 4, 5, 6, 7, 8, 9]);
      // One callback per chunk, cumulative, ending exactly at total.
      expect(progress, [
        [3, 9],
        [5, 9],
        [9, 9],
      ]);
    });

    test('propagates a stream error (and download() would clean up)', () {
      final dest = File('${dir.path}/err.bin');
      final boom = Stream<List<int>>.error(const SocketException('drop'));
      expect(writeStreamToFile(boom, 0, dest, null), throwsA(isA<SocketException>()));
    });
  });
}
