import 'package:flutter/cupertino.dart';

/// Design tokens for the woofer app: an iOS Human Interface aesthetic
/// (Cupertino widgets, large-title nav, SF-like type) with a frosted-glass
/// treatment layered over a soft gradient background.
///
/// Everything here is a plain constant or pure helper so it can be reused
/// anywhere without pulling in widgets. Screen widgets live under lib/widgets.

/// 8pt spacing scale (iOS uses multiples of 4/8).
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Corner radii. Glass surfaces sit in the 20–28 range per the design spec.
abstract final class AppRadius {
  static const double control = 14; // buttons, small chips
  static const double card = 22; // cards, list sections, format rows
  static const double sheet = 28; // modal sheets, large panels
}

/// WOOFER brand + semantic colors (see design/brand identity). The mark is a
/// violet equalizer on dark navy; the palette follows suit.
abstract final class AppColors {
  /// Brand violet — the primary accent (buttons, active states, progress).
  static const CupertinoDynamicColor accent = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF6D5DF6), // light bg: a touch deeper for contrast
    darkColor: Color(0xFF9184D9), // brand violet
  );

  static const Color violetLight = Color(0xFFB5ABFC);
  static const Color violetDeep = Color(0xFF796CBF);
  static const Color coral = Color(0xFFFF9A8F); // warm secondary accent

  /// Decorative gradient blob colors that give the glass something to refract.
  static const Color blobA = Color(0xFF9184D9); // brand violet
  static const Color blobB = Color(0xFFB5ABFC); // light violet
  static const Color blobC = coral; // coral
}

/// Frosted-glass parameters and reusable decoration bits.
abstract final class AppGlass {
  /// Default blur strength for a single frosted layer. Keep one blur per
  /// surface; nesting BackdropFilters tanks performance.
  static const double blurSigma = 18;

  /// White overlay opacity for the frosted tint (dark vs light background).
  static double tintOpacity(Brightness b) => b == Brightness.dark ? 0.12 : 0.20;

  /// 1px hairline border at ~20% white per the spec.
  static Border hairline([double opacity = 0.20]) =>
      Border.all(color: CupertinoColors.white.withValues(alpha: opacity), width: 1);

  /// Soft, diffuse shadow — no hard drop shadow. Negative spread keeps it airy.
  static List<BoxShadow> softShadow(Brightness b) => [
        BoxShadow(
          color: CupertinoColors.black.withValues(alpha: b == Brightness.dark ? 0.45 : 0.14),
          blurRadius: 30,
          spreadRadius: -10,
          offset: const Offset(0, 14),
        ),
      ];

  /// Translucent fill for nav bars / sheets — a touch more opaque than cards
  /// so text stays legible over busy backgrounds. Cupertino nav bars blur this
  /// automatically when the alpha is < 1.
  static Color navFill(Brightness b) => b == Brightness.dark
      ? const Color(0xFF232532).withValues(alpha: 0.62) // brand navy
      : const Color(0xFFF3F5FE).withValues(alpha: 0.62);
}

/// Soft gradient background per brightness. GlassBackground paints this and
/// floats a couple of blurred color blobs on top for depth.
abstract final class AppBackground {
  static LinearGradient gradient(Brightness b) => b == Brightness.dark
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF161826), Color(0xFF1C1930), Color(0xFF0F111C)], // brand navy
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5F4FF), Color(0xFFE7E5FE), Color(0xFFF3F5FE)], // brand violet-whites
        );
}

/// The app-wide Cupertino theme. Type is set in Inter (the WOOFER brand face);
/// page headers use a heavy ExtraBold weight for the bold, punchy brand look.
abstract final class AppTheme {
  /// The brand typeface. Declared in pubspec; weights 400–900 available.
  static const String fontFamily = 'Inter';

  static CupertinoThemeData of(Brightness brightness) {
    final label = CupertinoColors.label.resolveFrom0(brightness);
    return CupertinoThemeData(
      brightness: brightness,
      primaryColor: AppColors.accent,
      scaffoldBackgroundColor: const Color(0x00000000), // transparent: glass shows the gradient
      textTheme: CupertinoTextThemeData(
        primaryColor: AppColors.accent,
        // Large page titles ("WOOFER.", "Formats", "Downloading", "History") —
        // ExtraBold Inter. [FINE-TUNE] bump to w900 (Black) for an even heavier mark.
        navLargeTitleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: label,
        ),
        navTitleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 17,
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

extension on CupertinoDynamicColor {
  /// Resolve a dynamic color against a bare [Brightness] (no context needed).
  Color resolveFrom0(Brightness b) =>
      b == Brightness.dark ? darkColor : color;
}
