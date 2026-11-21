import 'package:flutter/widgets.dart';

/// True when the user turned on Android's "Remove animations" (MediaQuery
/// disableAnimations). Infinite decorative loops must freeze when this is set.
bool reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// True when the system font size is large enough (>130%) that side-by-side
/// controls no longer fit on a phone and should stack instead.
bool largeText(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(10) > 13;
