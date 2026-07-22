import 'package:flutter_test/flutter_test.dart';
import 'package:woofer/main.dart';

void main() {
  testWidgets('app boots into the glass gallery', (tester) async {
    await tester.pumpWidget(const WooferApp());
    expect(find.text('Glass Kit'), findsWidgets);
  });
}
