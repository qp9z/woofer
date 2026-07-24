import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woofer/main.dart';
import 'package:woofer/state/download_controller.dart';
import 'package:woofer/ui/screens/splash_screen.dart';

void main() {
  testWidgets('app shows the brand splash, then the downloader home', (tester) async {
    // Override history so the offstage Library tab doesn't hit sqflite off-device.
    await tester.pumpWidget(ProviderScope(
      overrides: [historyListProvider.overrideWith((ref) async => [])],
      child: const WooferApp(),
    ));

    // Splash first — the animated mark holds briefly.
    await tester.pump();
    expect(find.byType(SplashScreen), findsOneWidget);

    // Let the hold elapse and the cross-fade finish. Fixed pumps, not settle:
    // the aurora, the equalizer and the Fetch sheen all animate forever.
    await tester.pump(SplashScreen.hold);
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.text('Fetch'), findsOneWidget);
    expect(find.text('VIDEO LINK'), findsOneWidget);
  });
}
