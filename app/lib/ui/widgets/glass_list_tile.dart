import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';
import 'glass_container.dart';

/// An iOS-style row: leading, title/subtitle, trailing (chevron by default
/// when tappable). No Material ripple — tap fades via CupertinoButton.
///
/// Performance: leave [frosted] false and group several tiles inside ONE
/// [GlassContainer] (see [GlassListSection]) so the whole group shares a
/// single blur. Set [frosted] true only for a standalone row.
class GlassListTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool frosted;
  final bool showChevron;
  final EdgeInsetsGeometry padding;

  const GlassListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.frosted = false,
    this.showChevron = true,
    this.padding = const EdgeInsets.symmetric(
        horizontal: AppSpacing.md, vertical: AppSpacing.sm + 4),
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);

    final trailingWidget = trailing ??
        (onTap != null && showChevron
            ? Icon(CupertinoIcons.chevron_right,
                size: 16, color: CupertinoColors.tertiaryLabel.resolveFrom(context))
            : null);

    Widget row = Row(
      children: [
        if (leading != null) ...[
          IconTheme.merge(
            data: IconThemeData(color: labelColor, size: 22),
            child: leading!,
          ),
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              DefaultTextStyle.merge(
                style: TextStyle(fontSize: 17, letterSpacing: -0.2, color: labelColor),
                child: title,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                DefaultTextStyle.merge(
                  style: TextStyle(fontSize: 14, color: secondary),
                  child: subtitle!,
                ),
              ],
            ],
          ),
        ),
        if (trailingWidget != null) ...[
          const SizedBox(width: AppSpacing.sm),
          trailingWidget,
        ],
      ],
    );

    Widget content = Padding(padding: padding, child: row);

    if (onTap != null) {
      content = CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        minimumSize: Size.zero,
        child: content,
      );
    }

    if (frosted) {
      return GlassContainer(padding: EdgeInsets.zero, child: content);
    }
    return content;
  }
}

/// Groups tiles into one frosted panel with hairline separators — the iOS
/// inset-grouped list look, and the performant way to show many rows (one blur
/// for the whole section instead of one per row).
class GlassListSection extends StatelessWidget {
  final List<GlassListTile> tiles;
  final EdgeInsetsGeometry? margin;

  const GlassListSection({super.key, required this.tiles, this.margin});

  @override
  Widget build(BuildContext context) {
    final divider = Container(
      height: 0.5,
      margin: const EdgeInsetsDirectional.only(start: AppSpacing.md),
      color: CupertinoColors.separator.resolveFrom(context),
    );

    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      rows.add(tiles[i]);
      if (i != tiles.length - 1) rows.add(divider);
    }

    return GlassContainer(
      margin: margin,
      padding: EdgeInsets.zero,
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }
}
