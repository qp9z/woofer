import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';

/// Soft gradient wash with a few blurred color blobs — the canvas the frosted
/// glass refracts. Cheap: gradients only, no BackdropFilter here.
class GlassBackground extends StatelessWidget {
  final Widget? child;
  const GlassBackground({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final blobAlpha = brightness == Brightness.dark ? 0.45 : 0.35;

    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppBackground.gradient(brightness)),
      child: Stack(
        children: [
          _Blob(color: AppColors.blobA, alpha: blobAlpha, top: -80, left: -60, size: 320),
          _Blob(color: AppColors.blobB, alpha: blobAlpha, top: 140, right: -90, size: 300),
          _Blob(color: AppColors.blobC, alpha: blobAlpha * 0.9, bottom: -70, left: -40, size: 300),
          if (child != null) Positioned.fill(child: child!),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double alpha, size;
  final double? top, left, right, bottom;
  const _Blob({
    required this.color,
    required this.alpha,
    required this.size,
    this.top,
    this.left,
    this.right,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: 0),
            ]),
          ),
        ),
      ),
    );
  }
}

/// The standard screen shell: gradient background + iOS large-title nav bar
/// (frosted) + safe-area-aware scrolling body. Use this instead of a bare
/// Scaffold so every screen shares the same glass/iOS language.
///
/// Pass [children] for the common case (a scrolling column of content) or
/// [slivers] when you need full sliver control.
class GlassScaffold extends StatelessWidget {
  final String? title;
  final Widget? leading;
  final Widget? trailing;

  /// Body content, laid out in a padded scroll view under the nav bar.
  final List<Widget>? children;

  /// Escape hatch for custom sliver layouts (mutually exclusive with [children]).
  final List<Widget>? slivers;

  final EdgeInsetsGeometry padding;

  const GlassScaffold({
    super.key,
    this.title,
    this.leading,
    this.trailing,
    this.children,
    this.slivers,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  }) : assert(children == null || slivers == null,
            'Provide children or slivers, not both.');

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);

    final navBar = CupertinoSliverNavigationBar(
      largeTitle: title == null ? null : Text(title!),
      leading: leading,
      trailing: trailing,
      backgroundColor: AppGlass.navFill(brightness), // translucent -> auto-blurred
      border: Border(
        bottom: BorderSide(
          color: CupertinoColors.white.withValues(alpha: 0.15),
          width: 0,
        ),
      ),
    );

    final body = slivers != null
        ? SliverSafeArea(top: false, sliver: SliverList.list(children: slivers!))
        : SliverSafeArea(
            top: false,
            sliver: SliverPadding(
              padding: padding,
              sliver: SliverList.list(children: children ?? const []),
            ),
          );

    return GlassBackground(
      child: CupertinoPageScaffold(
        backgroundColor: const Color(0x00000000), // let the gradient through
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [navBar, body],
        ),
      ),
    );
  }
}
