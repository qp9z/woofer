import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:woofer/models/media_format.dart';
import 'package:woofer/models/video_info.dart';
import 'package:woofer/services/api_exception.dart';
import 'package:woofer/services/history_service.dart';
import 'package:woofer/state/download_controller.dart';
import 'package:woofer/state/download_state.dart';
import 'package:woofer/state/share_intent.dart';
import 'package:woofer/ui/screens/home_shell.dart';
import 'package:woofer/ui/screens/splash_screen.dart';
import 'package:woofer/ui/theme/app_theme.dart';

/// Pump [home] inside the app theme with the providers that would otherwise hit
/// sqflite / the platform. With [reduce] (default) the system "Remove
/// animations" setting is on, so the aurora, sheen and stripe freeze and
/// `pumpAndSettle` is safe; pass `reduce: false` to keep the loops running.
Future<void> pumpApp(
  WidgetTester t,
  Widget home, {
  List<Override> overrides = const [],
  List<HistoryEntry> history = const [],
  bool reduce = true,
  Size size = const Size(412, 892), // a phone, not flutter_test's 800x600
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);
  if (reduce) {
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  }
  addTearDown(t.platformDispatcher.clearAllTestValues);
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        historyListProvider.overrideWith((ref) async => history),
        sharedUrlProvider.overrideWith((ref) => const Stream.empty()),
        ...overrides,
      ],
      child: CupertinoApp(theme: AppTheme.of(Brightness.dark), home: home),
    ),
  );
  if (reduce) {
    await t.pumpAndSettle();
  } else {
    await t.pump();
  }
}

/// A controller pinned to one state, so a screen can be shown mid-download.
class _Fixed extends DownloadController {
  _Fixed(this.s);
  final DownloadState s;
  @override
  DownloadState build() => s;
}

const _mp4 = MediaFormat(
  formatId: '137',
  ext: 'mp4',
  resolution: '1080p',
  hasAudio: false,
  hasVideo: true,
);

const _info = VideoInfo(
  title: 'A Very Good Clip',
  uploader: 'Someone',
  duration: 187,
  formats: [
    _mp4,
    MediaFormat(formatId: '140', ext: 'm4a', hasAudio: true, hasVideo: false),
  ],
);

final _entries = [
  HistoryEntry(
    id: 1,
    title: 'First Clip',
    sourceUrl: 'https://youtu.be/a',
    filePath: 'content://media/1',
    format: '1920x1080',
    size: 1 << 20,
  ),
  HistoryEntry(
    id: 2,
    title: 'Second Clip',
    sourceUrl: 'https://youtu.be/b',
    filePath: 'content://media/2',
    format: 'medium',
    size: 1 << 19,
  ),
];

Override _state(DownloadState s) =>
    downloadControllerProvider.overrideWith(() => _Fixed(s));

/// Every tappable needs a label a screen reader can speak, and a hit area of at
/// least 44 px (AppTouch.min; iOS's guideline is the same 44).
Future<void> expectAccessible(WidgetTester t) async {
  await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(t, meetsGuideline(iOSTapTargetGuideline));
}

void main() {
  group('reduced motion', () {
    testWidgets('with Remove animations on, the whole shell settles', (t) async {
      // pumpAndSettle inside pumpApp times out if any infinite loop still runs.
      await pumpApp(t, const HomeShell());
      expect(find.text('VIDEO LINK'), findsOneWidget);
    });

    testWidgets('control: without it, the shell keeps animating', (t) async {
      await pumpApp(t, const HomeShell(), reduce: false);
      await t.pump(const Duration(milliseconds: 100));
      expect(t.binding.hasScheduledFrame, isTrue);
    });

    // Only shown while Processing, so the shell test above never builds it.
    testWidgets('the indeterminate stripe freezes only under reduced motion', (
      t,
    ) async {
      final fixed = downloadControllerProvider.overrideWith(
        () => _Fixed(const Processing(_mp4, 'Merging…')),
      );
      await pumpApp(t, const HomeShell(), overrides: [fixed]);
      expect(find.text('Merging…'), findsOneWidget); // settled with it showing
    });

    testWidgets('the splash (equalizer mark) settles too', (t) async {
      await pumpApp(t, const SplashScreen());
      expect(find.byType(SplashScreen), findsOneWidget);
    });
  });

  group('labels and tap targets', () {
    testWidgets('every tab of the shell', (t) async {
      final handle = t.ensureSemantics();
      await pumpApp(
        t,
        const HomeShell(),
        history: _entries,
      );
      await expectAccessible(t); // Download

      await t.tap(find.byIcon(CupertinoIcons.list_bullet));
      await t.pumpAndSettle();
      expect(find.text('First Clip'), findsOneWidget);
      await expectAccessible(t); // Library

      await t.tap(find.byIcon(CupertinoIcons.gear_alt));
      await t.pumpAndSettle();
      await expectAccessible(t); // Settings
      handle.dispose();
    });

    for (final (name, state) in <(String, DownloadState)>[
      ('downloading, size known', Downloading(format: _mp4, received: 5, total: 10)),
      ('downloading, size unknown', Downloading(format: _mp4, received: 5, total: -1)),
      ('processing', const Processing(_mp4, 'Merging…')),
      ('formats ready', const FormatsReady(_info)),
      ('failed', const Failed(ApiErrorCode.network, 'No connection.')),
    ]) {
      testWidgets('Download tab: $name', (t) async {
        final handle = t.ensureSemantics();
        await pumpApp(t, const HomeShell(), overrides: [_state(state)]);
        await expectAccessible(t);
        handle.dispose();
      });
    }

    testWidgets('the URL field with text shows a labelled clear button', (t) async {
      final handle = t.ensureSemantics();
      await pumpApp(t, const HomeShell());
      await t.enterText(find.byType(CupertinoTextField), 'https://youtu.be/x');
      await t.pumpAndSettle();
      expect(find.bySemanticsLabel('Clear link'), findsOneWidget);
      await expectAccessible(t);
      handle.dispose();
    });

    testWidgets('the format sheet', (t) async {
      final handle = t.ensureSemantics();
      await pumpApp(t, const HomeShell(), overrides: [_state(const FormatsReady(_info))]);
      await t.tap(find.text('Options'));
      await t.pumpAndSettle();
      expect(find.text('AVAILABLE QUALITIES'), findsOneWidget);
      expect(find.bySemanticsLabel('Close'), findsOneWidget);
      await expectAccessible(t);
      handle.dispose();
    });

    testWidgets('the About sheet', (t) async {
      final handle = t.ensureSemantics();
      await pumpApp(t, const HomeShell());
      await t.tap(find.bySemanticsLabel('About Woofer'));
      await t.pumpAndSettle();
      expect(find.text('Developer'.toUpperCase()), findsOneWidget);
      await expectAccessible(t);
      handle.dispose();
    });

    testWidgets('the Library actions sheet', (t) async {
      final handle = t.ensureSemantics();
      await pumpApp(
        t,
        const HomeShell(),
        history: _entries,
      );
      await t.tap(find.byIcon(CupertinoIcons.list_bullet));
      await t.pumpAndSettle();
      await t.tap(find.bySemanticsLabel('More actions for First Clip'));
      await t.pumpAndSettle();
      expect(find.text('Remove from library'), findsOneWidget);
      await expectAccessible(t);
      handle.dispose();
    });
  });
}
