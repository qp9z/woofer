import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:woofer/models/media_format.dart';
import 'package:woofer/models/video_info.dart';
import 'package:woofer/services/api_exception.dart';
import 'package:woofer/services/cover_fetcher.dart';
import 'package:woofer/services/foreground_service.dart';
import 'package:woofer/services/history_service.dart';
import 'package:woofer/services/media_processor.dart';
import 'package:woofer/services/storage_service.dart';
import 'package:woofer/services/ytdlp_extractor.dart';
import 'package:woofer/state/download_controller.dart';
import 'package:woofer/state/download_state.dart';

const _muxed = MediaFormat(
  formatId: '18',
  ext: 'mp4',
  resolution: '360p',
  filesize: 900,
  hasAudio: true,
  hasVideo: true,
);
const _videoOnly = MediaFormat(
  formatId: '137',
  ext: 'mp4',
  resolution: '1080p',
  filesize: 5000,
  hasAudio: false,
  hasVideo: true,
);
const _audioOnly = MediaFormat(
  formatId: '140',
  ext: 'm4a',
  filesize: 500,
  hasAudio: true,
  hasVideo: false,
);
const _info = VideoInfo(
  title: 'Clip',
  thumbnail: 't',
  uploader: 'Chan',
  formats: [_videoOnly, _muxed, _audioOnly],
);

/// Fake yt-dlp extractor. Records calls; `download` pings progress and returns a
/// per-format temp path without touching disk.
class _FakeYtdlp extends YtdlpExtractor {
  _FakeYtdlp({this.extractError})
    : super(channel: const MethodChannel('ytdlp_fake'));
  final ApiException? extractError;
  final List<String> downloaded = [];
  final List<String> downloadUrls = [];
  final List<String> extractedUrls = [];
  int extractCalls = 0;
  int cancels = 0;

  @override
  Future<void> cancel() async => cancels++;

  @override
  Future<VideoInfo> extractInfo(String url) async {
    extractCalls++;
    extractedUrls.add(url);
    if (extractError != null) throw extractError!;
    return _info;
  }

  @override
  Future<String> download(
    String url,
    String formatId, {
    void Function(int received, int total)? onProgress,
    String? dir,
  }) async {
    downloaded.add(formatId);
    downloadUrls.add(url);
    onProgress?.call(512, 1024);
    return '/tmp/woofer_$formatId.bin';
  }
}

/// Lets tests complete extractions in any order.
class _ControlledExtractYtdlp extends _FakeYtdlp {
  final Map<String, Completer<VideoInfo>> pending = {};

  @override
  Future<VideoInfo> extractInfo(String url) {
    extractCalls++;
    extractedUrls.add(url);
    return pending.putIfAbsent(url, Completer<VideoInfo>.new).future;
  }
}

class _UnexpectedExtractYtdlp extends _FakeYtdlp {
  @override
  Future<VideoInfo> extractInfo(String url) async {
    throw StateError('internal extractor detail');
  }
}

/// Holds the first transfer open so callers can attempt conflicting work.
class _BlockingDownloadYtdlp extends _FakeYtdlp {
  final Completer<void> firstStarted = Completer<void>();
  final Completer<String> firstDownload = Completer<String>();
  int downloadCalls = 0;

  @override
  Future<String> download(
    String url,
    String formatId, {
    void Function(int received, int total)? onProgress,
    String? dir,
  }) {
    downloadCalls++;
    downloaded.add(formatId);
    downloadUrls.add(url);
    if (downloadCalls == 1) {
      firstStarted.complete();
      return firstDownload.future;
    }
    onProgress?.call(512, 1024);
    return Future.value('/tmp/woofer_$formatId.bin');
  }

  @override
  Future<void> cancel() async {
    cancels++;
    if (!firstDownload.isCompleted) {
      firstDownload.completeError(
        const ApiException(code: ApiErrorCode.unknown, message: 'cancelled'),
      );
    }
  }
}

class _FakeProcessor extends MediaProcessor {
  final List<String> ops = [];

  @override
  Future<String> mergeVideoAudio(
    String video,
    String audio, {
    bool deleteInputs = true,
  }) async {
    ops.add('merge:$video+$audio');
    return '/tmp/merged.mp4';
  }

  @override
  Future<String> toMp3(
    String input, {
    int bitrateKbps = 192,
    bool deleteInputs = true,
    String? coverPath,
    String? title,
    String? artist,
  }) async {
    ops.add(
      'mp3:$input@$bitrateKbps'
      '${coverPath == null ? '' : ' +cover:$coverPath'}'
      '${title == null ? '' : ' +title:$title'}'
      '${artist == null ? '' : ' +artist:$artist'}',
    );
    return '/tmp/out.mp3';
  }
}

class _BlockingProcessor extends _FakeProcessor {
  final Completer<void> mergeStarted = Completer<void>();
  final Completer<String> mergeResult = Completer<String>();

  @override
  Future<String> mergeVideoAudio(
    String video,
    String audio, {
    bool deleteInputs = true,
  }) {
    ops.add('merge:$video+$audio');
    mergeStarted.complete();
    return mergeResult.future;
  }
}

class _FakeCover implements CoverFetcher {
  _FakeCover({this.result = '/tmp/cover.jpg'});
  final String? result;
  String? requestedUrl;

  @override
  Future<String?> fetch(String? url, String dir) async {
    requestedUrl = url;
    return result;
  }
}

class _FakeStorage extends StorageService {
  // Mirrors the real API 29+ result: `path` is MediaStore's *display* path, only
  // `uri` can actually be opened.
  _FakeStorage({
    this.result = const StorageResult(
      StorageStatus.success,
      path: 'Download/woofer/Clip.mp4',
      uri: 'content://media/external/downloads/42',
    ),
  });
  final StorageResult result;
  File? saved;

  @override
  Future<StorageResult> saveToDownloads(
    File source, {
    String? fileName,
    String mimeType = 'application/octet-stream',
  }) async {
    saved = source;
    return result;
  }
}

/// Records what the download would put on screen outside the app.
class _FakeForeground extends ForegroundService {
  final List<String> shown = []; // progress texts, in order
  final List<String> results = []; // "title|text|uri"
  int hides = 0;
  void Function()? cancelHandler;

  @override
  Future<void> show(
    String title, {
    required String text,
    int percent = -1,
  }) async {
    shown.add(percent >= 0 ? '$text @$percent%' : text);
  }

  @override
  Future<void> hide() async => hides++;

  @override
  Future<void> showResult(
    String title,
    String text, {
    String? uri,
    String? mimeType,
  }) async {
    results.add('$title|$text|$uri');
  }

  @override
  void onCancelRequested(void Function() onCancel) => cancelHandler = onCancel;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HistoryService history;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    history = HistoryService(db);
    await history.init();
  });

  ProviderContainer makeContainer({
    _FakeYtdlp? ytdlp,
    _FakeProcessor? processor,
    _FakeStorage? storage,
    _FakeForeground? foreground,
    _FakeCover? cover,
    DownloadTempDirectoryFactory? tempDirectoryFactory,
  }) {
    final c = ProviderContainer(
      overrides: [
        ytdlpExtractorProvider.overrideWithValue(ytdlp ?? _FakeYtdlp()),
        mediaProcessorProvider.overrideWithValue(processor ?? _FakeProcessor()),
        storageServiceProvider.overrideWithValue(storage ?? _FakeStorage()),
        foregroundServiceProvider.overrideWithValue(
          foreground ?? _FakeForeground(),
        ),
        coverFetcherProvider.overrideWithValue(cover ?? _FakeCover()),
        historyServiceProvider.overrideWith((ref) async => history),
        if (tempDirectoryFactory != null)
          downloadTempDirectoryProvider.overrideWithValue(tempDirectoryFactory),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('extract', () {
    test('resolves to formats via yt-dlp', () async {
      final ytdlp = _FakeYtdlp();
      final c = makeContainer(ytdlp: ytdlp);

      await c
          .read(downloadControllerProvider.notifier)
          .extract('https://youtu.be/abc');

      expect(ytdlp.extractCalls, 1);
      final s = c.read(downloadControllerProvider);
      expect(s, isA<FormatsReady>());
      expect((s as FormatsReady).formats, hasLength(3));
    });

    test('extraction failure surfaces the error code', () async {
      final ytdlp = _FakeYtdlp(
        extractError: const ApiException(
          code: ApiErrorCode.private,
          message: 'private',
        ),
      );
      final c = makeContainer(ytdlp: ytdlp);

      await c
          .read(downloadControllerProvider.notifier)
          .extract('https://youtu.be/abc');

      final s = c.read(downloadControllerProvider);
      expect(s, isA<Failed>());
      expect((s as Failed).code, ApiErrorCode.private);
    });

    test(
      'the newest concurrent extraction wins even when the older one finishes last',
      () async {
        final ytdlp = _ControlledExtractYtdlp();
        final c = makeContainer(ytdlp: ytdlp);
        final ctrl = c.read(downloadControllerProvider.notifier);
        const firstInfo = VideoInfo(title: 'First', formats: [_muxed]);
        const secondInfo = VideoInfo(title: 'Second', formats: [_muxed]);

        final first = ctrl.extract('https://example.com/first');
        final second = ctrl.extract('https://example.com/second');

        ytdlp.pending['https://example.com/second']!.complete(secondInfo);
        await second;
        expect(
          (c.read(downloadControllerProvider) as FormatsReady).info.title,
          'Second',
        );

        ytdlp.pending['https://example.com/first']!.complete(firstInfo);
        await first;
        expect(
          (c.read(downloadControllerProvider) as FormatsReady).info.title,
          'Second',
        );
        expect(ytdlp.extractedUrls, [
          'https://example.com/first',
          'https://example.com/second',
        ]);
      },
    );

    test(
      'an unexpected extraction failure is sanitized and leaves the controller usable',
      () async {
        final c = makeContainer(ytdlp: _UnexpectedExtractYtdlp());
        final ctrl = c.read(downloadControllerProvider.notifier);

        await ctrl.extract('https://example.com/video');

        final failed = c.read(downloadControllerProvider) as Failed;
        expect(failed.code, ApiErrorCode.unknown);
        expect(
          failed.message,
          'Could not inspect this link. Please try again.',
        );
        expect(failed.message, isNot(contains('internal extractor detail')));
        expect(ctrl.canExtract, isTrue);
      },
    );
  });

  group('download pipeline', () {
    /// Run extract → select → download, capturing every state emitted.
    Future<List<DownloadState>> run(
      ProviderContainer c,
      MediaFormat fmt,
    ) async {
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
      // The Library tab feeds filePath straight back to openFile/shareFile, so it
      // has to be the openable uri — MediaStore's display path resolves to nothing.
      final rows = await history.getAll();
      expect(rows.single.filePath, 'content://media/external/downloads/42');
    });

    test(
      'falls back to the saved path when there is no uri (legacy API <=28)',
      () async {
        final c = makeContainer(
          storage: _FakeStorage(
            result: const StorageResult(
              StorageStatus.success,
              path: '/storage/emulated/0/Download/woofer/Clip.mp4',
            ),
          ),
        );

        await run(c, _muxed);

        final rows = await history.getAll();
        expect(
          rows.single.filePath,
          '/storage/emulated/0/Download/woofer/Clip.mp4',
        );
      },
    );

    test(
      'video-only format: downloads video + audio, merges, then done',
      () async {
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
      },
    );

    test(
      'audio-only format: transcodes to MP3 at 192k with the cover attached',
      () async {
        final ytdlp = _FakeYtdlp();
        final proc = _FakeProcessor();
        final cover = _FakeCover();
        final c = makeContainer(ytdlp: ytdlp, processor: proc, cover: cover);

        final seen = await run(c, _audioOnly);

        expect(c.read(downloadControllerProvider), isA<Done>());
        expect(proc.ops.single, contains('@192'));
        // The artwork comes from the video's own thumbnail and reaches ffmpeg,
        // along with the tags that make it read as a track rather than a filename.
        expect(cover.requestedUrl, 't'); // _info.thumbnail
        expect(proc.ops.single, contains('+cover:/tmp/cover.jpg'));
        expect(proc.ops.single, contains('+title:Clip'));
        expect(proc.ops.single, contains('+artist:Chan'));
        expect(seen.whereType<Processing>().single.label, contains('MP3'));
      },
    );

    test(
      'no thumbnail: still produces the MP3, just without artwork',
      () async {
        final proc = _FakeProcessor();
        final c = makeContainer(
          processor: proc,
          cover: _FakeCover(result: null),
        );

        await run(c, _audioOnly);

        expect(c.read(downloadControllerProvider), isA<Done>());
        expect(proc.ops.single, isNot(contains('+cover')));
      },
    );

    test('notifications walk the phases and end on a tappable result', () async {
      final fg = _FakeForeground();
      final c = makeContainer(foreground: fg, ytdlp: _FakeYtdlp());
      // HomeShell resets the controller the moment it sees Done, and that lands
      // before the pipeline's finally does. The outcome has to survive it.
      c.listen(downloadControllerProvider, (_, next) {
        if (next is Done) c.read(downloadControllerProvider.notifier).reset();
      });

      await run(c, _videoOnly); // video-only => downloads, merges, saves

      expect(fg.shown.first, 'Starting…');
      // Progress carries real byte counts, not a bare percentage.
      expect(fg.shown, contains('Downloading · 512 B of 1.0 KB @50%'));
      expect(fg.shown, contains('Merging video and audio'));
      expect(fg.shown, contains('Saving to Downloads'));
      // The ongoing notification is torn down before the result is posted —
      // stopping the service would otherwise take the result down with it.
      expect(fg.hides, 1);
      expect(
        fg.results.single,
        'Clip|Saved to Downloads · tap to open|content://media/external/downloads/42',
      );
    });

    test(
      'a failure notifies the honest headline and no file to open',
      () async {
        final fg = _FakeForeground();
        final c = makeContainer(
          foreground: fg,
          storage: _FakeStorage(
            result: const StorageResult(
              StorageStatus.permissionDenied,
              message: 'denied',
            ),
          ),
        );

        await run(c, _muxed);

        expect(fg.hides, 1);
        expect(fg.results.single, 'Something went wrong|denied|null');
      },
    );

    test(
      'cancelling from the notification stops the download silently',
      () async {
        final fg = _FakeForeground();
        final ytdlp = _FakeYtdlp();
        final c = makeContainer(foreground: fg, ytdlp: ytdlp);
        final ctrl = c.read(downloadControllerProvider.notifier);

        await ctrl.extract('https://youtu.be/abc');
        ctrl.selectFormat(_muxed);
        final pending = ctrl.download();
        fg.cancelHandler!(); // the notification's Cancel button
        await pending;

        expect(c.read(downloadControllerProvider), isA<FormatsReady>());
        expect(await history.getAll(), isEmpty);
        // The transfer itself is aborted, not just flagged — otherwise a 4K cancel
        // sits there downloading for another few minutes.
        expect(ytdlp.cancels, 1);
        expect(fg.hides, 1); // notification cleared
        expect(
          fg.results,
          isEmpty,
        ); // ...but no "it failed" — the user did this
      },
    );

    test(
      'a replacement extraction is rejected while a download owns yt-dlp',
      () async {
        final ytdlp = _BlockingDownloadYtdlp();
        final c = makeContainer(ytdlp: ytdlp);
        final ctrl = c.read(downloadControllerProvider.notifier);

        await ctrl.extract('https://example.com/original');
        ctrl.selectFormat(_muxed);
        final pending = ctrl.download();
        await ytdlp.firstStarted.future;

        await ctrl.extract('https://example.com/replacement');

        expect(c.read(downloadControllerProvider), isA<Downloading>());
        expect(ytdlp.extractedUrls, ['https://example.com/original']);
        ytdlp.firstDownload.complete('/tmp/woofer_18.bin');
        await pending;

        expect(ytdlp.downloadUrls, ['https://example.com/original']);
        expect(c.read(downloadControllerProvider), isA<Done>());
      },
    );

    test(
      'temporary-directory failure becomes Failed and releases the lifecycle',
      () async {
        final foreground = _FakeForeground();
        final c = makeContainer(
          foreground: foreground,
          tempDirectoryFactory: () async => throw FileSystemException(
            'disk full at private path',
            r'C:\private\woofer',
          ),
        );
        final ctrl = c.read(downloadControllerProvider.notifier);

        await ctrl.extract('https://example.com/original');
        ctrl.selectFormat(_muxed);
        await ctrl.download();

        final failed = c.read(downloadControllerProvider) as Failed;
        expect(failed.code, ApiErrorCode.unknown);
        expect(
          failed.message,
          'Could not access temporary storage. Check free space and try again.',
        );
        expect(failed.message, isNot(contains('private path')));
        expect(foreground.shown, ['Starting…']);
        expect(foreground.hides, 1);
        expect(
          foreground.results.single,
          'Something went wrong|${failed.message}|null',
        );
        expect(ctrl.canExtract, isTrue);
        expect(await history.getAll(), isEmpty);
      },
    );

    test(
      'a replacement extraction is rejected while media is processing',
      () async {
        final ytdlp = _FakeYtdlp();
        final processor = _BlockingProcessor();
        final c = makeContainer(ytdlp: ytdlp, processor: processor);
        final ctrl = c.read(downloadControllerProvider.notifier);

        await ctrl.extract('https://example.com/original');
        ctrl.selectFormat(_videoOnly);
        final pending = ctrl.download();
        await processor.mergeStarted.future;
        expect(c.read(downloadControllerProvider), isA<Processing>());

        await ctrl.extract('https://example.com/replacement');

        expect(c.read(downloadControllerProvider), isA<Processing>());
        expect(ytdlp.extractedUrls, ['https://example.com/original']);
        processor.mergeResult.complete('/tmp/merged.mp4');
        await pending;
        expect(c.read(downloadControllerProvider), isA<Done>());
      },
    );

    test(
      'cancel and immediate restart cannot overlap native downloads',
      () async {
        final ytdlp = _BlockingDownloadYtdlp();
        final c = makeContainer(ytdlp: ytdlp);
        final ctrl = c.read(downloadControllerProvider.notifier);

        await ctrl.extract('https://example.com/original');
        ctrl.selectFormat(_muxed);
        final cancelled = ctrl.download();
        await ytdlp.firstStarted.future;

        ctrl.cancel();
        await ctrl.download(); // ignored while the cancelled call is unwinding
        expect(ytdlp.downloadCalls, 1);

        await cancelled;
        final ready = c.read(downloadControllerProvider);
        expect(ready, isA<FormatsReady>());
        expect((ready as FormatsReady).selected, _muxed);

        await ctrl.download();
        expect(ytdlp.downloadCalls, 2);
        expect(
          ytdlp.downloadUrls,
          everyElement('https://example.com/original'),
        );
        expect(c.read(downloadControllerProvider), isA<Done>());
      },
    );

    test(
      'a save failure becomes Failed(unknown) and records no history',
      () async {
        final c = makeContainer(
          storage: _FakeStorage(
            result: const StorageResult(
              StorageStatus.permissionDenied,
              message: 'denied',
            ),
          ),
        );

        await run(c, _muxed);

        final s = c.read(downloadControllerProvider);
        expect(s, isA<Failed>());
        expect((s as Failed).code, ApiErrorCode.unknown);
        expect(await history.getAll(), isEmpty);
      },
    );
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
