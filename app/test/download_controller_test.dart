import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:woofer/models/media_format.dart';
import 'package:woofer/models/video_info.dart';
import 'package:woofer/services/api_exception.dart';
import 'package:woofer/services/history_service.dart';
import 'package:woofer/services/media_processor.dart';
import 'package:woofer/services/storage_service.dart';
import 'package:woofer/services/ytdlp_extractor.dart';
import 'package:woofer/state/download_controller.dart';
import 'package:woofer/state/download_state.dart';

const _muxed =
    MediaFormat(formatId: '18', ext: 'mp4', resolution: '360p', filesize: 900, hasAudio: true, hasVideo: true);
const _videoOnly =
    MediaFormat(formatId: '137', ext: 'mp4', resolution: '1080p', filesize: 5000, hasAudio: false, hasVideo: true);
const _audioOnly = MediaFormat(formatId: '140', ext: 'm4a', filesize: 500, hasAudio: true, hasVideo: false);
const _info = VideoInfo(title: 'Clip', thumbnail: 't', formats: [_videoOnly, _muxed, _audioOnly]);

/// Fake yt-dlp extractor. Records calls; `download` pings progress and returns a
/// per-format temp path without touching disk.
class _FakeYtdlp extends YtdlpExtractor {
  _FakeYtdlp({this.extractError}) : super(channel: const MethodChannel('ytdlp_fake'));
  final ApiException? extractError;
  final List<String> downloaded = [];
  int extractCalls = 0;

  @override
  Future<VideoInfo> extractInfo(String url) async {
    extractCalls++;
    if (extractError != null) throw extractError!;
    return _info;
  }

  @override
  Future<String> download(String url, String formatId,
      {void Function(int received, int total)? onProgress, String? dir}) async {
    downloaded.add(formatId);
    onProgress?.call(512, 1024);
    return '/tmp/woofer_$formatId.bin';
  }
}

class _FakeProcessor extends MediaProcessor {
  final List<String> ops = [];

  @override
  Future<String> mergeVideoAudio(String video, String audio, {bool deleteInputs = true}) async {
    ops.add('merge:$video+$audio');
    return '/tmp/merged.mp4';
  }

  @override
  Future<String> toMp3(String input, [int bitrateKbps = 192, bool deleteInputs = true]) async {
    ops.add('mp3:$input@$bitrateKbps');
    return '/tmp/out.mp3';
  }
}

class _FakeStorage extends StorageService {
  _FakeStorage({this.result = const StorageResult(StorageStatus.success, path: '/Download/woofer/Clip.mp4')});
  final StorageResult result;
  File? saved;

  @override
  Future<StorageResult> saveToDownloads(File source, {String? fileName, String mimeType = 'application/octet-stream'}) async {
    saved = source;
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HistoryService history;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    final db = await databaseFactory.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(singleInstance: false));
    history = HistoryService(db);
    await history.init();
  });

  ProviderContainer makeContainer({
    _FakeYtdlp? ytdlp,
    _FakeProcessor? processor,
    _FakeStorage? storage,
  }) {
    final c = ProviderContainer(overrides: [
      ytdlpExtractorProvider.overrideWithValue(ytdlp ?? _FakeYtdlp()),
      mediaProcessorProvider.overrideWithValue(processor ?? _FakeProcessor()),
      storageServiceProvider.overrideWithValue(storage ?? _FakeStorage()),
      historyServiceProvider.overrideWith((ref) async => history),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('extract', () {
    test('resolves to formats via yt-dlp', () async {
      final ytdlp = _FakeYtdlp();
      final c = makeContainer(ytdlp: ytdlp);

      await c.read(downloadControllerProvider.notifier).extract('https://youtu.be/abc');

      expect(ytdlp.extractCalls, 1);
      final s = c.read(downloadControllerProvider);
      expect(s, isA<FormatsReady>());
      expect((s as FormatsReady).formats, hasLength(3));
    });

    test('extraction failure surfaces the error code', () async {
      final ytdlp = _FakeYtdlp(extractError: const ApiException(code: ApiErrorCode.private, message: 'private'));
      final c = makeContainer(ytdlp: ytdlp);

      await c.read(downloadControllerProvider.notifier).extract('https://youtu.be/abc');

      final s = c.read(downloadControllerProvider);
      expect(s, isA<Failed>());
      expect((s as Failed).code, ApiErrorCode.private);
    });
  });

  group('download pipeline', () {
    /// Run extract → select → download, capturing every state emitted.
    Future<List<DownloadState>> run(ProviderContainer c, MediaFormat fmt) async {
      final seen = <DownloadState>[];
      c.listen(downloadControllerProvider, (_, next) => seen.add(next));
      final ctrl = c.read(downloadControllerProvider.notifier);
      await ctrl.extract('https://youtu.be/abc');
      ctrl.selectFormat(fmt);
      await ctrl.download();
      return seen;
    }

    test('muxed format: download only, no processing, saved + recorded', () async {
      final ytdlp = _FakeYtdlp();
      final proc = _FakeProcessor();
      final c = makeContainer(ytdlp: ytdlp, processor: proc);

      final seen = await run(c, _muxed);

      expect(c.read(downloadControllerProvider), isA<Done>());
      expect(seen.whereType<Downloading>(), isNotEmpty);
      expect(seen.whereType<Processing>(), isEmpty); // muxed needs no ffmpeg
      expect(proc.ops, isEmpty);
      expect(ytdlp.downloaded, ['18']);
      final rows = await history.getAll();
      expect(rows.single.filePath, '/Download/woofer/Clip.mp4');
    });

    test('video-only format: downloads video + audio, merges, then done', () async {
      final ytdlp = _FakeYtdlp();
      final proc = _FakeProcessor();
      final c = makeContainer(ytdlp: ytdlp, processor: proc);

      final seen = await run(c, _videoOnly);

      expect(c.read(downloadControllerProvider), isA<Done>());
      // Both the video and the best audio track were fetched.
      expect(ytdlp.downloaded, ['137', '140']);
      // A merge ran, and the Processing state was surfaced with a merge label.
      expect(proc.ops.single, startsWith('merge:'));
      final processing = seen.whereType<Processing>().single;
      expect(processing.label, contains('Merging'));
    });

    test('audio-only format: transcodes to MP3 at 192k', () async {
      final ytdlp = _FakeYtdlp();
      final proc = _FakeProcessor();
      final c = makeContainer(ytdlp: ytdlp, processor: proc);

      final seen = await run(c, _audioOnly);

      expect(c.read(downloadControllerProvider), isA<Done>());
      expect(proc.ops.single, contains('@192'));
      expect(seen.whereType<Processing>().single.label, contains('MP3'));
    });

    test('a save failure becomes Failed(unknown) and records no history', () async {
      final c = makeContainer(
          storage: _FakeStorage(result: const StorageResult(StorageStatus.permissionDenied, message: 'denied')));

      await run(c, _muxed);

      final s = c.read(downloadControllerProvider);
      expect(s, isA<Failed>());
      expect((s as Failed).code, ApiErrorCode.unknown);
      expect(await history.getAll(), isEmpty);
    });
  });

  test('cancel returns to format selection without saving', () async {
    final c = makeContainer();
    final ctrl = c.read(downloadControllerProvider.notifier);

    await ctrl.extract('https://youtu.be/abc');
    ctrl.selectFormat(_muxed);
    final pending = ctrl.download();
    ctrl.cancel();
    await pending;

    final s = c.read(downloadControllerProvider);
    expect(s, isA<FormatsReady>());
    expect((s as FormatsReady).selected, _muxed);
    expect(await history.getAll(), isEmpty);
  });
}
