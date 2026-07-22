import 'dart:ui';

import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';

/// A frosted-glass surface: blurred backdrop, translucent tint, hairline
/// border, rounded corners, and a soft diffuse shadow. Drop it anywhere —
/// cards, sheets, nav bars, the format list all use this.
///
/// One BackdropFilter per instance. Do NOT nest GlassContainers with blur on;
/// stack their children instead, or set [enableBlur] false on inner layers.
class GlassContainer extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;

  /// Full override for corner shape (e.g. top-only rounding for sheets).
  /// Takes precedence over [radius].
  final BorderRadiusGeometry? borderRadius;
  final double blur;

  /// Overlay fill. Defaults to a brightness-aware white frost.
  final Color? tint;

  /// Overrides the default hairline border. Pass `Border()` for none... prefer
  /// leaving it for the iOS look.
  final Border? border;

  /// Overrides the default soft shadow. Pass `const []` to drop it.
  final List<BoxShadow>? shadow;

  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  /// Turn the blur off on cheap/inner layers to stay performant.
  final bool enableBlur;

  const GlassContainer({
    super.key,
    this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin,
    this.radius = AppRadius.card,
    this.borderRadius,
    this.blur = AppGlass.blurSigma,
    this.tint,
    this.border,
    this.shadow,
    this.width,
    this.height,
    this.alignment,
    this.enableBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final corners = borderRadius ?? BorderRadius.circular(radius);
    final fill = tint ??
        CupertinoColors.white.withValues(alpha: AppGlass.tintOpacity(brightness));

    final surface = Container(
      width: width,
      height: height,
      padding: padding,
      alignment: alignment,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: corners,
        border: border ?? AppGlass.hairline(),
      ),
      child: child,
    );

    final clipped = ClipRRect(
      borderRadius: corners,
      child: enableBlur
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: surface,
            )
          : surface,
    );

    // Shadow lives on an outer box so it isn't clipped away by the ClipRRect.
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: corners,
        boxShadow: shadow ?? AppGlass.softShadow(brightness),
      ),
      child: clipped,
    );
  }
}
