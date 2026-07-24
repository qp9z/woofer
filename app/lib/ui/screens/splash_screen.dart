import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';
import '../widgets/aurora_background.dart';
import '../widgets/woofer_mark.dart';
import '../widgets/wordmark.dart';

/// Brand splash: the equalizer mark pulsing over the drifting aurora. The native
/// Android launch screen (a static window background) hands off to this the
/// moment Flutter draws, so the mark appears to come alive in place.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  /// How long the splash holds before the shell takes over. Roughly one and a
  /// third beats of the 1.1s equalizer loop — a brand moment, not a wait.
  static const Duration hold = Duration(milliseconds: 1400);

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      backgroundColor: AppColors.ground,
      child: AuroraBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              WooferMark(
                size: 104,
                tile: WooferTile.accent,
                bars: WooferBars.light,
                animated: true,
              ),
              SizedBox(height: AppSpacing.lg),
              Wordmark(fontSize: 30),
            ],
          ),
        ),
      ),
    );
  }
}
