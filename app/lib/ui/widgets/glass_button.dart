import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';
import 'glass_container.dart';

/// A tappable frosted-glass button with a subtle spring press (scale + dim),
/// no Material ripple. One blur layer — don't drop it inside another glass
/// panel with blur on; pass `enableBlur: false` if you do.
///
/// [GlassButton.primary] gives an accent-tinted filled CTA.
class GlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final Color? tint;
  final bool enableBlur;
  final bool expand; // stretch to max width
  final IconData? icon;

  const GlassButton({
    super.key,
    required this.child,
    this.onPressed,
    this.padding =
        const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm + 2),
    this.radius = AppRadius.control,
    this.blur = AppGlass.blurSigma,
    this.tint,
    this.enableBlur = true,
    this.expand = false,
    this.icon,
  });

  /// Filled accent variant for the main call-to-action.
  const GlassButton.primary({
    super.key,
    required this.child,
    this.onPressed,
    this.padding =
        const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm + 2),
    this.radius = AppRadius.control,
    this.blur = AppGlass.blurSigma,
    this.enableBlur = true,
    this.expand = false,
    this.icon,
  }) : tint = _primarySentinel;

  static const Color _primarySentinel = Color(0x00ABCDEF);

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _down = false;

  bool get _enabled => widget.onPressed != null;

  void _set(bool v) {
    if (_enabled && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final isPrimary = widget.tint == GlassButton._primarySentinel;
    final tint = isPrimary
        ? AppColors.accent.resolveFrom(context).withValues(alpha: 0.9) // brand violet CTA
        : widget.tint;

    Widget label = DefaultTextStyle.merge(
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: isPrimary
            ? CupertinoColors.white
            : CupertinoColors.label.resolveFrom(context),
      ),
      child: IconTheme.merge(
        data: IconThemeData(
          size: 20,
          color: isPrimary
              ? CupertinoColors.white
              : CupertinoColors.label.resolveFrom(context),
        ),
        child: widget.child,
      ),
    );

    if (widget.icon != null) {
      label = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.icon, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Flexible(child: label),
        ],
      );
    }

    final panel = GlassContainer(
      radius: widget.radius,
      blur: widget.blur,
      enableBlur: widget.enableBlur,
      tint: tint,
      padding: widget.padding,
      alignment: Alignment.center,
      width: widget.expand ? double.infinity : null,
      // Primary CTA reads as solid: firmer border, keep the soft shadow.
      border: isPrimary
          ? Border.all(color: CupertinoColors.white.withValues(alpha: 0.35), width: 1)
          : null,
      child: label,
    );

    return MouseRegion(
      cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        child: AnimatedScale(
          scale: _down ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutBack,
          child: AnimatedOpacity(
            opacity: _enabled ? (_down ? 0.85 : 1.0) : 0.5,
            duration: const Duration(milliseconds: 120),
            child: panel,
          ),
        ),
      ),
    );
  }
}
