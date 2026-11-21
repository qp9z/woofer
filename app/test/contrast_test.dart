import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woofer/ui/theme/app_theme.dart';

/// WCAG 2.x contrast. Computed from the tokens rather than sampled from pixels
/// (flutter's textContrastGuideline): the drifting aurora blobs make a pixel
/// sample non-deterministic.
double _lin(double c) =>
    c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) =>
    0.2126 * _lin(c.r) + 0.7152 * _lin(c.g) + 0.0722 * _lin(c.b);

double contrast(Color a, Color b) {
  final l1 = _luminance(a), l2 = _luminance(b);
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
}

void main() {
  // The two surfaces text sits on: the aurora's top stop, and a glass card
  // (5% white) over it.
  final ground = AppColors.auroraA;
  final glass = Color.alphaBlend(
    CupertinoColors.white.withValues(alpha: 0.05),
    AppColors.auroraA,
  );

  test('the helper agrees with the WCAG reference values', () {
    expect(contrast(const Color(0xFF000000), const Color(0xFFFFFFFF)), closeTo(21, 0.01));
    expect(contrast(const Color(0xFF777777), const Color(0xFFFFFFFF)), closeTo(4.48, 0.02));
  });

  const body = {
    'text': AppColors.text,
    'textDim': AppColors.textDim,
    'n400': AppColors.n400,
    'n500': AppColors.n500,
    'a200': AppColors.a200,
    'a300': AppColors.a300,
  };

  for (final MapEntry(key: name, value: color) in body.entries) {
    test('$name meets WCAG AA (4.5:1) on the ground and on glass', () {
      expect(contrast(color, ground), greaterThanOrEqualTo(4.5));
      expect(contrast(color, glass), greaterThanOrEqualTo(4.5));
    });
  }

  // Documents why the URL placeholder moved to n500: n600 is a decoration
  // colour (chevrons), not a text colour.
  test('n600 fails AA, so it must not be used for text', () {
    expect(contrast(AppColors.n600, ground), lessThan(4.5));
    expect(contrast(AppColors.n600, glass), lessThan(4.5));
  });
}
