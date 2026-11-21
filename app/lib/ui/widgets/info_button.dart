import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';
import 'tap_target.dart';

/// The round ⓘ in every tab's title row; opens the About sheet.
class InfoButton extends StatelessWidget {
  const InfoButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TapTarget(
    onTap: onTap,
    label: 'About Woofer',
    child: Container(
      width: AppTouch.min,
      height: AppTouch.min,
      margin: const EdgeInsets.only(top: 1),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: CupertinoColors.white.withValues(alpha: 0.05),
        border: AppGlass.hairline(0.10),
      ),
      child: const Icon(CupertinoIcons.info, size: 24, color: AppColors.a200),
    ),
  );
}
