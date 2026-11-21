import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woofer/services/api_exception.dart';
import 'package:woofer/state/download_controller.dart';
import 'package:woofer/state/download_state.dart';
import 'package:woofer/ui/screens/home_shell.dart';
import 'package:woofer/ui/screens/splash_screen.dart';
import 'support/app_harness.dart';

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
        () => FixedDownload(const Processing(sampleMp4, 'Merging…')),
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
        history: sampleEntries,
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
      ('downloading, size known', Downloading(format: sampleMp4, received: 5, total: 10)),
      ('downloading, size unknown', Downloading(format: sampleMp4, received: 5, total: -1)),
      ('processing', const Processing(sampleMp4, 'Merging…')),
      ('formats ready', const FormatsReady(sampleInfo)),
      ('failed', const Failed(ApiErrorCode.network, 'No connection.')),
    ]) {
      testWidgets('Download tab: $name', (t) async {
        final handle = t.ensureSemantics();
        await pumpApp(t, const HomeShell(), overrides: [downloadState(state)]);
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
      await pumpApp(t, const HomeShell(), overrides: [downloadState(const FormatsReady(sampleInfo))]);
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
        history: sampleEntries,
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
