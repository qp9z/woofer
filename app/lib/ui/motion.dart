import 'package:flutter/widgets.dart';

/// True when the user turned on Android's "Remove animations" (MediaQuery
/// disableAnimations). Infinite decorative loops must freeze when this is set.
bool reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;
