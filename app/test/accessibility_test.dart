import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:woofer/models/media_format.dart';
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
  bool reduce = true,
}) async {
  if (reduce) {
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  }
  addTearDown(t.platformDispatcher.clearAllTestValues);
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        historyListProvider.overrideWith((ref) async => []),
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
}
