import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woofer/main.dart';

void main() {
  testWidgets('app boots into the downloader home screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: WooferApp()));
    expect(find.text('WOOFER.'), findsWidgets);
    expect(find.text('Fetch'), findsOneWidget);
  });
}
