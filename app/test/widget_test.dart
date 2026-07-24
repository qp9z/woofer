import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woofer/main.dart';
import 'package:woofer/state/download_controller.dart';

void main() {
  testWidgets('app boots into the downloader home', (tester) async {
    // Override history so the offstage Library tab doesn't hit sqflite on device.
    await tester.pumpWidget(ProviderScope(
      overrides: [historyListProvider.overrideWith((ref) async => [])],
      child: const WooferApp(),
    ));
    // One frame only: the aurora + Fetch sheen animate forever, so no settle.
    await tester.pump();

    expect(find.text('Fetch'), findsOneWidget);
    expect(find.text('VIDEO LINK'), findsOneWidget);
  });
}
