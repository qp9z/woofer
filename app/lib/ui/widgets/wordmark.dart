import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';

/// "WOOFER." set in the brand display weight, with the period in accent.
/// Uppercase by design — the period is part of the name.
class Wordmark extends StatelessWidget {
  final double fontSize;
  final double height;
  const Wordmark({super.key, required this.fontSize, this.height = 1.0});

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.02 * fontSize,
            height: height,
            color: AppColors.text,
          ),
          children: const [
            TextSpan(text: 'WOOFER'),
            TextSpan(text: '.', style: TextStyle(color: AppColors.a300)),
          ],
        ),
      );
}
