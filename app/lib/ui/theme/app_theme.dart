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

/// Brand + semantic colors. Text/background use CupertinoColors dynamic
/// variants so they adapt to light/dark automatically.
abstract final class AppColors {
  static const CupertinoDynamicColor accent = CupertinoColors.systemBlue;

  /// Decorative gradient blob colors that give the glass something to refract.
  static const Color blobA = Color(0xFF6D5DF6); // indigo
  static const Color blobB = Color(0xFF00C2FF); // cyan
  static const Color blobC = Color(0xFFFF7AB6); // pink
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
      ? const Color(0xFF1C1C1E).withValues(alpha: 0.62)
      : const Color(0xFFF2F2F7).withValues(alpha: 0.62);
}

/// Soft gradient background per brightness. GlassBackground paints this and
/// floats a couple of blurred color blobs on top for depth.
abstract final class AppBackground {
  static LinearGradient gradient(Brightness b) => b == Brightness.dark
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B0B12), Color(0xFF141020), Color(0xFF0A0A0A)],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF0FF), Color(0xFFF3ECFF), Color(0xFFFDF2F8)],
        );
}

/// The app-wide Cupertino theme. iOS type scale; leaves fontFamily on the
/// system default (`.SF Pro` on iOS, platform default on Android).
///
// ponytail: to get true SF Pro on Android, drop the .otf into fonts/, declare
// it in pubspec, and set `fontFamily` below. System default until you need it.
abstract final class AppTheme {
  static CupertinoThemeData of(Brightness brightness) => CupertinoThemeData(
        brightness: brightness,
        primaryColor: AppColors.accent,
        scaffoldBackgroundColor: const Color(0x00000000), // transparent: glass shows the gradient
        textTheme: CupertinoTextThemeData(
          primaryColor: AppColors.accent,
          navLargeTitleTextStyle: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            color: CupertinoColors.label.resolveFrom0(brightness),
          ),
          navTitleTextStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: CupertinoColors.label.resolveFrom0(brightness),
          ),
          textStyle: TextStyle(
            fontSize: 17,
            letterSpacing: -0.2,
            color: CupertinoColors.label.resolveFrom0(brightness),
          ),
        ),
      );
}

extension on CupertinoDynamicColor {
  /// Resolve a dynamic color against a bare [Brightness] (no context needed).
  Color resolveFrom0(Brightness b) =>
      b == Brightness.dark ? darkColor : color;
}
