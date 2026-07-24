import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';
import 'glass_container.dart';

/// A frosted bottom sheet with a grabber, optional title, top-rounded corners,
/// and bottom safe-area padding. Slides up iOS-style.
///
/// Usage:
/// ```dart
/// GlassSheet.show(context, title: 'Choose quality', builder: (_) => ...);
/// ```
abstract final class GlassSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    String? title,
    bool isDismissible = true,
  }) {
    return showCupertinoModalPopup<T>(
      context: context,
      barrierDismissible: isDismissible,
      barrierColor: CupertinoColors.black.withValues(alpha: 0.35),
      builder: (ctx) => _GlassSheetPanel(title: title, child: builder(ctx)),
    );
  }

  /// Full-control WOOFER sheet: dark frosted glass, top-rounded, grabber, slide
  /// up over a blurred scrim. The [builder] fills the whole body (no title row);
  /// use for the format and About sheets. Content scrolls if it overflows.
  static Future<T?> present<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool isDismissible = true,
  }) {
    return showCupertinoModalPopup<T>(
      context: context,
      barrierDismissible: isDismissible,
      barrierColor: CupertinoColors.black.withValues(alpha: 0.55),
      builder: (ctx) => _DesignSheetPanel(child: builder(ctx)),
    );
  }
}

/// A grabber pill for sheet headers.
class SheetGrabber extends StatelessWidget {
  const SheetGrabber({super.key});

  @override
  Widget build(BuildContext context) => Container(
        width: 38,
        height: 5,
        decoration: BoxDecoration(
          color: CupertinoColors.white.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(3),
        ),
      );
}

class _DesignSheetPanel extends StatelessWidget {
  final Widget child;
  const _DesignSheetPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom; // keyboard
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: GlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
          padding: EdgeInsets.zero,
          margin: EdgeInsets.zero,
          tint: const Color(0xFF1E2036).withValues(alpha: 0.72), // rgba(30,32,54,.72)
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassSheetPanel extends StatelessWidget {
  final String? title;
  final Widget child;
  const _GlassSheetPanel({this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom; // keyboard
    final topCorners = const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet));

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: GlassContainer(
          borderRadius: topCorners,
          padding: EdgeInsets.zero,
          // Cover the bottom edge so the rounded top reads as a sheet, not a card.
          margin: EdgeInsets.zero,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Grabber
                  Container(
                    width: 36,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey.resolveFrom(context)
                          .withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  if (title != null) ...[
                    Text(
                      title!,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
