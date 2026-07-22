import 'package:flutter_test/flutter_test.dart';
import 'package:woofer/state/share_intent.dart';

void main() {
  test('extracts a bare URL', () {
    expect(firstUrl('https://youtu.be/abc'), 'https://youtu.be/abc');
  });

  test('extracts the URL from title-prefixed shared text', () {
    expect(firstUrl('Cool clip https://youtu.be/abc more'), 'https://youtu.be/abc');
  });

  test('keeps query params, stops at whitespace', () {
    expect(firstUrl('https://y.com/w?v=1&t=2 trailing'), 'https://y.com/w?v=1&t=2');
  });

  test('returns null when there is no link', () {
    expect(firstUrl('just some text'), isNull);
  });
}
