import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woofer/services/api_exception.dart';
import 'package:woofer/state/download_controller.dart';
import 'package:woofer/state/download_state.dart';
import 'package:woofer/state/share_intent.dart';
import 'package:woofer/ui/format_utils.dart';
import 'package:woofer/ui/screens/home_shell.dart';

import 'support/app_harness.dart';

/// A controller the test steers by hand, so it can walk the shell through a
/// download without any yt-dlp behind it.
class _Driven extends DownloadController {
  @override
  DownloadState build() => const Idle();
  void go(DownloadState s) => state = s;
}

const _downloading = Downloading(format: sampleMp4, received: 5, total: 10);

/// Toasts hold for 2.6 s on a real Timer; flutter_test fails a test that ends
/// with one still pending, so every toast test finishes through here.
Future<void> _letToastExpire(WidgetTester t) =>
    t.pump(const Duration(seconds: 3));

void main() {
  Future<(_Driven, ProviderContainer)> pumpShell(WidgetTester t) async {
    await pumpApp(
      t,
      const HomeShell(),
      overrides: [downloadControllerProvider.overrideWith(_Driven.new)],
    );
    final container = ProviderScope.containerOf(t.element(find.byType(HomeShell)));
    return (container.read(downloadControllerProvider.notifier) as _Driven, container);
  }

  group('cancel', () {
    // Cancelling drops the controller back to FormatsReady. The shell used to
    // treat that like a fresh link and re-open the sheet the user had just
    // dismissed in order to cancel.
    testWidgets('is acknowledged and does not pop the format sheet open', (t) async {
      final (ctrl, _) = await pumpShell(t);

      ctrl.go(_downloading);
      await t.pumpAndSettle();
      ctrl.go(const FormatsReady(sampleInfo)); // what cancel() ends in
      await t.pumpAndSettle();

      expect(find.text('Download cancelled.'), findsOneWidget);
      expect(find.text('AVAILABLE QUALITIES'), findsNothing);
      await _letToastExpire(t);
    });

    testWidgets('also while processing', (t) async {
      final (ctrl, _) = await pumpShell(t);

      ctrl.go(const Processing(sampleMp4, 'Merging…'));
      await t.pumpAndSettle();
      ctrl.go(const FormatsReady(sampleInfo));
      await t.pumpAndSettle();

      expect(find.text('Download cancelled.'), findsOneWidget);
      expect(find.text('AVAILABLE QUALITIES'), findsNothing);
      await _letToastExpire(t);
    });

    // Control: the same destination from a fetch must still open the sheet,
    // or the guard above has simply broken the normal flow.
    testWidgets('control: a freshly fetched link still opens the sheet', (t) async {
      final (ctrl, _) = await pumpShell(t);

      ctrl.go(const Loading());
      await t.pump(); // not settle: the Fetch spinner never stops
      ctrl.go(const FormatsReady(sampleInfo));
      await t.pumpAndSettle();

      expect(find.text('AVAILABLE QUALITIES'), findsOneWidget);
      expect(find.text('Download cancelled.'), findsNothing);
    });

    testWidgets('control: retry after a failure still opens the sheet', (t) async {
      final (ctrl, _) = await pumpShell(t);

      ctrl.go(const Loading());
      await t.pump(); // not settle: the Fetch spinner never stops
      ctrl.go(const Failed(ApiErrorCode.network, 'No connection.'));
      await t.pumpAndSettle();
      ctrl.go(const FormatsReady(sampleInfo));
      await t.pumpAndSettle();

      expect(find.text('AVAILABLE QUALITIES'), findsOneWidget);
    });
  });

  group('busy', () {
    testWidgets('a rejected share is explained with a toast', (t) async {
      final (_, container) = await pumpShell(t);
      expect(find.text(busyFetchMessage), findsNothing);

      container.read(shareRejectedProvider.notifier).bump();
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));

      expect(find.text(busyFetchMessage), findsOneWidget);
      await _letToastExpire(t);
    });

    for (final (name, state) in <(String, DownloadState)>[
      ('downloading', _downloading),
      ('processing', const Processing(sampleMp4, 'Merging…')),
    ]) {
      testWidgets('while $name, the greyed-out Fetch says why', (t) async {
        await pumpApp(t, const HomeShell(), overrides: [downloadState(state)]);
        expect(find.text(busyFetchMessage), findsOneWidget);
      });
    }

    testWidgets('and says nothing when idle', (t) async {
      await pumpApp(t, const HomeShell());
      expect(find.text(busyFetchMessage), findsNothing);
    });
  });

  testWidgets('a download with no known total admits it', (t) async {
    await pumpApp(
      t,
      const HomeShell(),
      overrides: [
        downloadState(
          const Downloading(format: sampleMp4, received: 5 * 1024 * 1024, total: -1),
        ),
      ],
    );
    expect(find.text('5.0 MB downloaded · size unknown'), findsOneWidget);
  });

  testWidgets('toasts are live regions, so a screen reader announces them', (t) async {
    final (_, container) = await pumpShell(t);
    final handle = t.ensureSemantics();
    container.read(shareRejectedProvider.notifier).bump();
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));

    final node = t.getSemantics(find.text(busyFetchMessage));
    expect(node.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
    handle.dispose();
    await _letToastExpire(t);
  });
}
