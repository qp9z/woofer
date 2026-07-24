import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';

/// The hero CTA: a blurple gradient pill with a white sheen sweeping across and
/// a soft glow, ink-dark label. Used for Fetch (home) and Download (sheet).
/// [loading] swaps the icon/label for a spinner + [loadingLabel].
class FetchButton extends StatefulWidget {
  final String label;
  final String loadingLabel;
  final IconData? icon;
  final bool loading;
  final bool expand;
  final VoidCallback? onPressed;

  const FetchButton({
    super.key,
    required this.label,
    this.loadingLabel = 'Fetching…',
    this.icon,
    this.loading = false,
    this.expand = true,
    this.onPressed,
  });

  @override
  State<FetchButton> createState() => _FetchButtonState();
}

class _FetchButtonState extends State<FetchButton> with SingleTickerProviderStateMixin {
  late final AnimationController _sheen =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3400))..repeat();
  bool _down = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const ink = AppColors.accentInk;

    Widget content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.loading)
          const CupertinoActivityIndicator(color: ink, radius: 10)
        else if (widget.icon != null)
          Icon(widget.icon, size: 22, color: ink),
        const SizedBox(width: AppSpacing.sm + 2),
        Flexible(
          child: Text(
            widget.loading ? widget.loadingLabel : widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: AppType.button,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
              color: ink,
            ),
          ),
        ),
      ],
    );

    final panel = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.control),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.fetchGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.a600.withValues(alpha: 0.4),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
        // Approximates the inset top highlight from the design recipe.
        border: Border.all(color: CupertinoColors.white.withValues(alpha: 0.4), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: Stack(
          children: [
            _Sheen(animation: _sheen),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.md + 1), // ~56px tall
              child: content,
            ),
          ],
        ),
      ),
    );

    return MouseRegion(
      cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _enabled ? widget.onPressed : null,
        onTapDown: _enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: _enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: _enabled ? () => setState(() => _down = false) : null,
        child: AnimatedScale(
          scale: _down ? 0.985 : 1,
          duration: const Duration(milliseconds: 120),
          child: AnimatedOpacity(
            opacity: _enabled || widget.loading ? 1 : 0.55,
            duration: const Duration(milliseconds: 120),
            child: widget.expand ? SizedBox(width: double.infinity, child: panel) : panel,
          ),
        ),
      ),
    );
  }
}

/// A skewed white bar that sweeps left→right on a loop.
class _Sheen extends StatelessWidget {
  final Animation<double> animation;
  const _Sheen({required this.animation});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            return AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                // -140% → 320% over the first 55% of the cycle, then hold off-screen.
                final phase = (animation.value / 0.55).clamp(0.0, 1.0);
                final x = (-1.4 + 4.6 * phase) * w;
                return Transform.translate(
                  offset: Offset(x, 0),
                  child: Transform(
                    transform: Matrix4.skewX(-18 * math.pi / 180),
                    child: Container(
                      width: w * 0.36,
                      height: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0x00FFFFFF),
                            Color(0x8CFFFFFF), // white @ 0.55
                            Color(0x00FFFFFF),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
