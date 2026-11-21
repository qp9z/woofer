import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:woofer/models/media_format.dart';
import 'package:woofer/models/video_info.dart';
import 'package:woofer/state/download_controller.dart';
import 'package:woofer/state/download_state.dart';
import 'package:woofer/services/history_service.dart';
import 'package:woofer/services/storage_service.dart';
import 'package:woofer/services/ytdlp_extractor.dart';
import 'package:woofer/state/share_intent.dart';
import 'package:woofer/ui/screens/home_shell.dart';
import 'package:woofer/ui/screens/library_tab.dart';
import 'package:woofer/ui/sheets/about_sheet.dart';
import 'package:woofer/ui/sheets/format_sheet.dart';
import 'package:woofer/ui/theme/app_theme.dart';

Widget _app(Widget home, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: CupertinoApp(theme: AppTheme.of(Brightness.dark), home: home),
    );

const _info = VideoInfo(
  title: 'A Very Good Clip',
  uploader: 'Someone',
  duration: 187,
  formats: [
    MediaFormat(
      formatId: '18',
      ext: 'mp4',
      resolution: '360p',
      filesize: 2 * 1024 * 1024,
      hasAudio: true,
      hasVideo: true,
    ),
    MediaFormat(
      formatId: '137',
      ext: 'mp4',
      resolution: '1080p',
      filesize: 5 * 1024 * 1024,
      hasAudio: false,
      hasVideo: true,
    ),
    MediaFormat(formatId: '140', ext: 'm4a', hasAudio: true, hasVideo: false),
  ],
);

class _RecordingDownloadController extends DownloadController {
  bool downloadCalled = false;

  @override
  DownloadState build() => const FormatsReady(_info);

  @override
  Future<void> download() async {
    downloadCalled = true;
  }
}

/// Reports a fixed yt-dlp version; everything else is never reached.
class _VersionedYtdlp extends YtdlpExtractor {
  _VersionedYtdlp(this._version) : super(channel: const MethodChannel('ytdlp_about_test'));
  final String _version;

  @override
  Future<String?> version() async => _version;
}

/// Records what the Library tried to open and whether anything could handle it.
class _OpenStorage extends StorageService {
  _OpenStorage({required this.opens});
  final bool opens;
  String? opened;

  @override
  Future<bool> openFile(String pathOrUri, {String mimeType = '*/*'}) async {
    opened = pathOrUri;
    return opens;
  }
}

final _libraryEntry = HistoryEntry(
  title: 'Gone Clip',
  sourceUrl: 'https://youtu.be/abc',
  filePath: 'content://media/external/downloads/9',
  format: '1920x1080',
);

/// An in-memory library, so removing a row really changes what the tab shows.
class _FakeHistory implements HistoryService {
  _FakeHistory(this.rows);
  final List<HistoryEntry> rows;

  @override
  Future<List<HistoryEntry>> getAll() async => List.of(rows);

  @override
  Future<int> delete(int id) async {
    final before = rows.length;
    rows.removeWhere((e) => e.id == id);
    return before - rows.length;
  }

  @override
  Future<int> clear() async {
    final n = rows.length;
    rows.clear();
    return n;
  }

  @override
  Future<void> init() async {}
  @override
  Future<int> add(HistoryEntry entry) async => 0;
  @override
  Future<void> close() async {}
}

List<HistoryEntry> _two() => [
  HistoryEntry(
    id: 1,
    title: 'Gone Clip',
    sourceUrl: 'https://youtu.be/a',
    filePath: 'content://media/external/downloads/1',
    format: '1920x1080',
  ),
  HistoryEntry(
    id: 2,
    title: 'Kept Song',
    sourceUrl: 'https://youtu.be/b',
    filePath: 'content://media/external/downloads/2',
    format: 'medium',
  ),
];

void main() {
  Future<_OpenStorage> tapLibraryRow(WidgetTester t, {required bool opens}) async {
    final storage = _OpenStorage(opens: opens);
    await t.pumpWidget(
      _app(
        const LibraryTab(),
        overrides: [
          historyListProvider.overrideWith((ref) async => [_libraryEntry]),
          storageServiceProvider.overrideWithValue(storage),
        ],
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    await t.tap(find.text('Gone Clip'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    return storage;
  }

  // A tap that does nothing reads as a broken app, and a user who deleted the
  // file from Downloads will hit exactly this.
  testWidgets('tapping a Library row whose file is gone says so', (t) async {
    final storage = await tapLibraryRow(t, opens: false);

    expect(storage.opened, 'content://media/external/downloads/9');
    expect(
      find.text("Couldn't open this file. It may have been moved or deleted."),
      findsOneWidget,
    );
  });

  testWidgets('tapping a Library row that opens shows no error', (t) async {
    final storage = await tapLibraryRow(t, opens: true);

    expect(storage.opened, 'content://media/external/downloads/9');
    expect(find.textContaining("Couldn't open"), findsNothing);
  });

  testWidgets('format sheet lists real formats with an Audio/Video toggle', (
    t,
  ) async {
    await t.pumpWidget(
      _app(
        Consumer(
          builder: (context, ref, _) => CupertinoButton(
            onPressed: () => showFormatSheet(context, ref, _info),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pump(); // start the sheet route
    await t.pump(const Duration(milliseconds: 400)); // slide it in

    expect(find.text('A Very Good Clip'), findsOneWidget);
    expect(find.text('Audio'), findsOneWidget);
    expect(find.text('Video'), findsOneWidget);
    // Video is the default kind; its row and the confirm label reflect it.
    expect(find.text('1080p · MP4'), findsOneWidget);
    expect(find.text('Download · 1080p · MP4'), findsOneWidget);
    // Note: don't pumpAndSettle — the confirm button's sheen loops forever.
  });

  testWidgets('untouched Download confirms the advertised best video', (
    t,
  ) async {
    late _RecordingDownloadController controller;
    await t.pumpWidget(
      _app(
        Consumer(
          builder: (context, ref, _) {
            controller =
                ref.read(downloadControllerProvider.notifier)
                    as _RecordingDownloadController;
            return CupertinoButton(
              onPressed: () => showFormatSheet(context, ref, _info),
              child: const Text('open default test'),
            );
          },
        ),
        overrides: [
          downloadControllerProvider.overrideWith(
            _RecordingDownloadController.new,
          ),
        ],
      ),
    );
    await t.tap(find.text('open default test'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));

    expect(find.text('Download · 1080p · MP4'), findsOneWidget);
    await t.tap(find.text('Download · 1080p · MP4'));
    await t.pump();

    final state = controller.state as FormatsReady;
    expect(state.selected?.formatId, '137');
    expect(controller.downloadCalled, isTrue);
  });

  testWidgets('Library tab renders the empty state', (t) async {
    await t.pumpWidget(
      _app(
        const LibraryTab(),
        overrides: [historyListProvider.overrideWith((ref) async => [])],
      ),
    );
    await t.pumpAndSettle();

    expect(find.text('Nothing here yet.'), findsOneWidget);
  });

  testWidgets('About shows the bundled yt-dlp version from the shared extractor', (
    t,
  ) async {
    await t.pumpWidget(
      _app(
        Builder(
          builder: (context) => CupertinoButton(
            onPressed: () => showAboutSheet(context),
            child: const Text('open about'),
          ),
        ),
        overrides: [
          // Must come from the provider: a fresh YtdlpExtractor would steal the
          // channel's single method-call handler from the real one.
          ytdlpExtractorProvider.overrideWithValue(_VersionedYtdlp('2026.10.26')),
        ],
      ),
    );

    await t.tap(find.text('open about'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));

    expect(find.text('yt-dlp 2026.10.26'), findsOneWidget);
  });

  // Riverpod 3 pauses listeners of offstage widgets. The Download tab sits in an
  // IndexedStack, so a link shared while Library is showing must still be routed:
  // the shell keeps the subscription alive and brings Download forward.
  testWidgets('a link shared while another tab is showing lands on Download', (
    t,
  ) async {
    final shares = StreamController<String>();
    addTearDown(shares.close);
    await t.pumpWidget(
      _app(
        const HomeShell(),
        overrides: [
          historyListProvider.overrideWith((ref) async => []),
          sharedUrlProvider.overrideWith((ref) => shares.stream),
        ],
      ),
    );
    await t.pump();

    // Library in front: Download is now offstage.
    await t.tap(find.byIcon(CupertinoIcons.list_bullet));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Nothing here yet.'), findsOneWidget);
    expect(find.text('VIDEO LINK'), findsNothing);

    shares.add('https://youtu.be/abc123');
    // Fixed pumps: the aurora animates forever, so pumpAndSettle would hang.
    for (var i = 0; i < 4; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Nothing here yet.'), findsNothing);
    expect(find.text('VIDEO LINK'), findsOneWidget);
    expect(
      find.widgetWithText(CupertinoTextField, 'https://youtu.be/abc123'),
      findsOneWidget,
    );
  });

  group('stale entries and clearing the library', () {
    late _FakeHistory history;
    late _OpenStorage storage;

    Future<void> pumpLibrary(WidgetTester t, {required bool opens}) async {
      storage = _OpenStorage(opens: opens);
      await t.pumpWidget(
        _app(
          const LibraryTab(),
          overrides: [
            historyServiceProvider.overrideWith((ref) async => history),
            storageServiceProvider.overrideWithValue(storage),
          ],
        ),
      );
      await t.pumpAndSettle();
    }

    setUp(() => history = _FakeHistory(_two()));

    testWidgets('a failed open offers to remove the stale row', (t) async {
      await pumpLibrary(t, opens: false);
      await t.tap(find.text('Gone Clip'));
      await t.pumpAndSettle();

      expect(storage.opened, 'content://media/external/downloads/1');
      expect(
        find.text('Removing only forgets it here — nothing else is deleted.'),
        findsOneWidget,
      );
      await t.tap(find.text('Remove from library'));
      await t.pumpAndSettle();

      expect(find.text('Gone Clip'), findsNothing);
      expect(find.text('Kept Song'), findsOneWidget);
      expect(history.rows.map((e) => e.id), [2]);
    });

    testWidgets('Keep leaves the row alone', (t) async {
      await pumpLibrary(t, opens: false);
      await t.tap(find.text('Gone Clip'));
      await t.pumpAndSettle();
      await t.tap(find.text('Keep'));
      await t.pumpAndSettle();

      expect(find.text('Gone Clip'), findsOneWidget);
      expect(history.rows, hasLength(2));
    });

    testWidgets('the actions sheet says the file stays in Downloads', (t) async {
      await pumpLibrary(t, opens: true);
      await t.tap(find.bySemanticsLabel('More actions for Gone Clip'));
      await t.pumpAndSettle();

      expect(
        find.text('Only removes it from this list — the file stays in Downloads.'),
        findsOneWidget,
      );
      await t.tap(find.text('Remove from library'));
      await t.pumpAndSettle();
      expect(find.text('Gone Clip'), findsNothing);
      // Opening was never attempted: removing a row never touches the file.
      expect(storage.opened, isNull);
    });

    testWidgets('Clear library asks first, then empties it', (t) async {
      await pumpLibrary(t, opens: true);
      await t.tap(find.text('Clear library'));
      await t.pumpAndSettle();

      expect(find.text('Clear your library?'), findsOneWidget);
      expect(
        find.text(
          'This removes all 2 entries from Woofer. Your downloaded files stay in Downloads.',
        ),
        findsOneWidget,
      );
      expect(history.rows, hasLength(2)); // asking changed nothing

      await t.tap(find.text('Clear'));
      await t.pumpAndSettle();

      expect(find.text('Nothing here yet.'), findsOneWidget);
      expect(history.rows, isEmpty);
      expect(find.text('Clear library'), findsNothing);
    });

    testWidgets('Cancel keeps every row', (t) async {
      await pumpLibrary(t, opens: true);
      await t.tap(find.text('Clear library'));
      await t.pumpAndSettle();
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();

      expect(find.text('Gone Clip'), findsOneWidget);
      expect(find.text('Kept Song'), findsOneWidget);
      expect(history.rows, hasLength(2));
    });

    testWidgets('there is nothing to clear in an empty library', (t) async {
      history = _FakeHistory([]);
      await pumpLibrary(t, opens: true);
      expect(find.text('Nothing here yet.'), findsOneWidget);
      expect(find.text('Clear library'), findsNothing);
    });

    testWidgets('a filter that matches nothing still offers Clear library', (
      t,
    ) async {
      history = _FakeHistory([_two().first]); // one video, no audio
      await pumpLibrary(t, opens: true);
      await t.tap(find.text('Audio'));
      await t.pumpAndSettle();

      expect(find.text('Nothing here yet.'), findsOneWidget);
      expect(find.text('Clear library'), findsOneWidget);
    });
  });
}
