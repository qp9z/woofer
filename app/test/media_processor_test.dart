import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:woofer/services/api_exception.dart';
import 'package:woofer/services/media_processor.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('woofer_mp'));
  tearDown(() => dir.deleteSync(recursive: true));

  File touch(String name) => File('${dir.path}/$name')..writeAsStringSync('x');

  /// A runner that records the args it got and writes a stub output file (the
  /// last arg), mimicking a successful ffmpeg run.
  ({FfmpegRun run, List<List<String>> calls}) okRunner() {
    final calls = <List<String>>[];
    return (
      run: (args) async {
        calls.add(args);
        File(args.last).writeAsStringSync('output');
        return null;
      },
      calls: calls,
    );
  }

  group('argument construction', () {
    test('mergeArgs maps one video + one audio track and stream-copies to mp4', () {
      final args = MediaProcessor.mergeArgs('/v.mp4', '/a.m4a', '/out.mp4');
      expect(args, containsAllInOrder(['-i', '/v.mp4', '-i', '/a.m4a']));
      expect(args, containsAllInOrder(['-map', '0:v:0']));
      expect(args, containsAllInOrder(['-map', '1:a:0']));
      expect(args, containsAllInOrder(['-c', 'copy']));
      expect(args.last, '/out.mp4');
    });

    test('mp3Args sets the bitrate, forces libmp3lame, and drops video', () {
      final args = MediaProcessor.mp3Args('/in.m4a', '/out.mp3', 192);
      expect(args, contains('-vn'));
      expect(args, containsAllInOrder(['-c:a', 'libmp3lame']));
      expect(args, containsAllInOrder(['-b:a', '192k']));
      expect(args.last, '/out.mp3');
    });
  });

  group('mergeVideoAudio', () {
    test('returns an mp4 path and deletes both inputs on success', () async {
      final r = okRunner();
      final v = touch('v.mp4');
      final a = touch('a.m4a');
      final proc = MediaProcessor(runner: r.run, workDir: dir);

      final out = await proc.mergeVideoAudio(v.path, a.path);

      expect(out, endsWith('.mp4'));
      expect(File(out).existsSync(), isTrue);
      expect(v.existsSync(), isFalse); // cleaned up
      expect(a.existsSync(), isFalse);
      expect(r.calls.single.last, out);
    });

    test('deleteInputs:false keeps the source files', () async {
      final r = okRunner();
      final v = touch('v.mp4');
      final a = touch('a.m4a');
      final proc = MediaProcessor(runner: r.run, workDir: dir);

      await proc.mergeVideoAudio(v.path, a.path, deleteInputs: false);

      expect(v.existsSync(), isTrue);
      expect(a.existsSync(), isTrue);
    });
  });

  group('toMp3', () {
    test('returns an mp3 path and deletes the input', () async {
      final r = okRunner();
      final input = touch('song.m4a');
      final proc = MediaProcessor(runner: r.run, workDir: dir);

      final out = await proc.toMp3(input.path, 192);

      expect(out, endsWith('.mp3'));
      expect(File(out).existsSync(), isTrue);
      expect(input.existsSync(), isFalse);
    });
  });

  group('failure handling', () {
    test('a failed run throws unknown, drops the partial output, keeps inputs', () async {
      final input = touch('in.m4a');
      // Runner writes a partial file then reports failure — the corrupt output
      // must not survive, but the input must, so the caller can retry.
      final proc = MediaProcessor(
        workDir: dir,
        runner: (args) async {
          File(args.last).writeAsStringSync('half');
          return 'Invalid data found when processing input';
        },
      );

      await expectLater(
        () => proc.toMp3(input.path),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', ApiErrorCode.unknown)),
      );
      expect(input.existsSync(), isTrue);
      expect(dir.listSync().where((e) => e.path.endsWith('.mp3')), isEmpty);
    });

    test('a runner that throws is mapped to ApiException', () async {
      final input = touch('in.m4a');
      final proc = MediaProcessor(
        workDir: dir,
        runner: (args) async => throw StateError('boom'),
      );
      await expectLater(() => proc.toMp3(input.path), throwsA(isA<ApiException>()));
    });

    test('success with no output file is treated as a failure', () async {
      final input = touch('in.m4a');
      final proc = MediaProcessor(
        workDir: dir,
        runner: (args) async => null, // claims success but writes nothing
      );
      await expectLater(() => proc.toMp3(input.path), throwsA(isA<ApiException>()));
      expect(input.existsSync(), isTrue); // input preserved on failure
    });
  });
}
