import 'package:flutter/cupertino.dart';

/// Design tokens for WOOFER — dark, calm, liquid-glass. One blurple accent over
/// a near-neutral deep ground; motion (drifting aurora) is the signature.
/// Ported from the brand handoff (design_handoff_woofer/THEME.md) — reference
/// these tokens, never hard-code hex in a widget.

/// 8pt spacing scale.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Type scale. The design prototype was drawn on a 340px-wide phone mock; these
/// are scaled ~1.2x for real handsets (~410dp) so copy is comfortably readable
/// at arm's length. Reference these — don't inline font sizes in widgets.
abstract final class AppType {
  static const double display = 36; // WOOFER.
  static const double header = 22; // LIBRARY / SETTINGS
  static const double button = 18; // Fetch / Download
  static const double title = 17; // sheet media title
  static const double bodyStrong = 16; // row titles
  static const double body = 15; // input text, settings labels, chips
  static const double meta = 14; // row subtitles, tips, footers
  static const double label = 13; // uppercase section labels
}

/// Touch ergonomics. The design handoff requires hit targets >= 44px.
abstract final class AppTouch {
  static const double min = 44;
}

/// Corner radii, per THEME.md.
abstract final class AppRadius {
  static const double chip = 13; // quality rows, chips, nav items
  static const double control = 17; // Fetch / primary buttons
  static const double input = 18; // URL pill
  static const double card = 18; // cards, media preview
  static const double navPill = 24; // floating nav bar
  static const double sheet = 28; // bottom sheets (top corners)
}

/// WOOFER color tokens (THEME.md). Dark-first: the app runs in Brightness.dark.
abstract final class AppColors {
  // --- Ground / surface ---
  static const Color ground = Color(0xFF0F1120);
  static const Color ground2 = Color(0xFF141626);
  static const Color auroraA = Color(0xFF22243E);
  static const Color auroraB = Color(0xFF191B30);
  static const Color auroraC = Color(0xFF131426);
  static const Color text = Color(0xFFE9E9ED);
  static const Color textDim = Color(0xFFB8BAD0);

  // --- Accent (blurple) ramp ---
  static const Color a100 = Color(0xFFF5F4FF);
  static const Color a200 = Color(0xFFE7E5FE);
  static const Color a300 = Color(0xFFD2CEFD);
  static const Color a400 = Color(0xFFB5ABFC);
  static const Color a500 = Color(0xFF9184D9);
  static const Color a600 = Color(0xFF796CBF);
  static const Color a700 = Color(0xFF5D5294);
  static const Color a800 = Color(0xFF423A6A);
  static const Color a900 = Color(0xFF2B2741);
  static const Color accentInk = Color(0xFF1A1730); // text/icon on accent fill

  // --- Neutral ramp (100 → 900) ---
  static const Color n100 = Color(0xFFF3F5FE);
  static const Color n200 = Color(0xFFE4E7F5);
  static const Color n300 = Color(0xFFCFD3E5);
  static const Color n400 = Color(0xFFB2B6CA);
  static const Color n500 = Color(0xFF9397AB);
  static const Color n600 = Color(0xFF75798C);
  static const Color n700 = Color(0xFF595D6C);
  static const Color n800 = Color(0xFF3F424D); // hairlines
  static const Color n900 = Color(0xFF292B31);

  /// Primary accent as a Cupertino dynamic color (used by nav/theme + existing
  /// glass widgets). Both brightnesses land on the brand violet.
  static const CupertinoDynamicColor accent = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF6D5DF6), // light ground: a touch deeper for contrast
    darkColor: a500,
  );

  /// Fetch / primary CTA gradient (135°).
  static const List<Color> fetchGradient = [
    Color(0xFFC3BAFF),
    Color(0xFF9D90EE),
    Color(0xFF8577D6),
  ];

  /// Aurora glow blobs (color + alpha), drifting behind the glass.
  static const Color blobA = a400; // top-left  rgba(181,171,252,.50)
  static const Color blobB = a600; // mid-right rgba(120,108,191,.42)
  static const Color blobC = Color(0xFFD68AAB); // lower-left rose rgba(214,138,171,.32)
  static const Color blobD = a500; // bottom-right rgba(145,132,217,.30)
}

/// Frosted-glass parameters and reusable decoration bits.
abstract final class AppGlass {
  /// Default blur strength for a primary `.glass` layer.
  static const double blurSigma = 22;

  /// Softer blur for `.glass-soft` (secondary surfaces).
  static const double blurSoft = 16;

  /// White overlay opacity for the frosted tint. `.glass` = 0.07 on dark.
  static double tintOpacity(Brightness b) => b == Brightness.dark ? 0.07 : 0.20;

  /// Hairline border at ~16% white (`.glass`). Use 0.10 for `.glass-soft`.
  static Border hairline([double opacity = 0.16]) =>
      Border.all(color: CupertinoColors.white.withValues(alpha: opacity), width: 1);

  /// Soft, diffuse shadow — no hard drop shadow.
  static List<BoxShadow> softShadow(Brightness b) => [
        BoxShadow(
          color: CupertinoColors.black.withValues(alpha: b == Brightness.dark ? 0.35 : 0.14),
          blurRadius: 34,
          spreadRadius: -10,
          offset: const Offset(0, 12),
        ),
      ];

  /// Translucent fill for nav bars / sheets.
  static Color navFill(Brightness b) => b == Brightness.dark
      ? const Color(0xFF1C1E34).withValues(alpha: 0.5) // nav pill (THEME.md)
      : const Color(0xFFF3F5FE).withValues(alpha: 0.62);
}

/// Soft gradient background per brightness. GlassBackground (glass_scaffold)
/// still paints this; the new shell uses AuroraBackground.
abstract final class AppBackground {
  static LinearGradient gradient(Brightness b) => b == Brightness.dark
      ? const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.auroraA, AppColors.auroraB, AppColors.auroraC],
          stops: [0.0, 0.42, 1.0],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5F4FF), Color(0xFFE7E5FE), Color(0xFFF3F5FE)],
        );
}

/// The app-wide Cupertino theme. Type is Inter; page/display titles use a heavy
/// weight with tight tracking for the bold WOOFER look.
abstract final class AppTheme {
  /// The brand typeface. Declared in pubspec; weights 400–900 available.
  static const String fontFamily = 'Inter';

  static CupertinoThemeData of(Brightness brightness) {
    final label = CupertinoColors.label.resolveFrom0(brightness);
    return CupertinoThemeData(
      brightness: brightness,
      primaryColor: AppColors.accent,
      scaffoldBackgroundColor: AppColors.ground,
      textTheme: CupertinoTextThemeData(
        primaryColor: AppColors.accent,
        navLargeTitleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: AppType.display,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.7,
          color: label,
        ),
        navTitleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: AppType.title,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: label,
        ),
        navActionTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.accent.resolveFrom0(brightness),
        ),
        actionTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.accent.resolveFrom0(brightness),
        ),
        tabLabelTextStyle: const TextStyle(fontFamily: fontFamily, fontSize: 10, letterSpacing: -0.24),
        pickerTextStyle: TextStyle(fontFamily: fontFamily, fontSize: 21, color: label),
        dateTimePickerTextStyle: TextStyle(fontFamily: fontFamily, fontSize: 21, color: label),
        textStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 17,
          letterSpacing: -0.2,
          color: label,
        ),
      ),
    );
  }
}

extension CupertinoDynamicColorResolve0 on CupertinoDynamicColor {
  /// Resolve a dynamic color against a bare [Brightness] (no context needed).
  Color resolveFrom0(Brightness b) => b == Brightness.dark ? darkColor : color;
}
