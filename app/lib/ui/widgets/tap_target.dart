import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';

/// The one way to make something tappable. Gives button semantics, a hit area of
/// at least [AppTouch.min] (44 px), and an optional [label] for icon-only
/// controls so a screen reader has something to say.
class TapTarget extends StatelessWidget {
  const TapTarget({
    super.key,
    required this.onTap,
    required this.child,
    this.label,
    this.selected,
    this.onLongPress,
    this.minSize = AppTouch.min,
  });

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget child;

  /// REQUIRED for icon-only controls. Replaces the child's own text.
  final String? label;

  /// For chips, tabs and radio-style rows.
  final bool? selected;
  final double minSize;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true, // its own node: a button inside a tappable row stays separate
    button: true,
    enabled: onTap != null,
    selected: selected,
    label: label,
    excludeSemantics: label != null, // a given label replaces child text
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
        child: Center(widthFactor: 1, heightFactor: 1, child: child),
      ),
    ),
  );
}
