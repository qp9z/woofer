import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';

/// The WOOFER logo mark: five vertical bars rising to a center peak
/// (equalizer/waveform) on an optional rounded tile. Geometry matches the
/// brand SVG exactly (100×100 viewBox), so it scales cleanly at any size.
///
/// Dependency-free (a CustomPainter, no flutter_svg): the mark is just five
/// rounded rects, cheaper to draw than to parse an SVG.
enum WooferTile { accent, dark, none }

enum WooferBars { light, accent }

class WooferMark extends StatelessWidget {
  final double size;
  final WooferTile tile;
  final WooferBars bars;

  const WooferMark({
    super.key,
    required this.size,
    this.tile = WooferTile.accent,
    this.bars = WooferBars.light,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _MarkPainter(tile: tile, bars: bars),
      );
}

class _MarkPainter extends CustomPainter {
  final WooferTile tile;
  final WooferBars bars;
  const _MarkPainter({required this.tile, required this.bars});

  // x, y, height on the 100×100 grid (width 9, rx 4.5 for every bar).
  static const _bars = <List<double>>[
    [11.5, 36.55, 26.9],
    [28.5, 27.0, 46.0],
    [45.5, 18.0, 64.0],
    [62.5, 27.0, 46.0],
    [79.5, 36.55, 26.9],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100.0;
    final rect = Offset.zero & size;

    // Tile.
    if (tile != WooferTile.none) {
      final tileRRect = RRect.fromRectAndRadius(rect, Radius.circular(22 * s));
      final gradient = tile == WooferTile.accent
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.a400, AppColors.a600])
          : const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF232532), Color(0xFF161826)]);
      canvas.drawRRect(tileRRect, Paint()..shader = gradient.createShader(rect));
    }

    // Bars.
    final barPaint = Paint();
    if (bars == WooferBars.accent) {
      barPaint.shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.a400, AppColors.a500],
      ).createShader(rect);
    } else {
      barPaint.color = tile == WooferTile.none ? CupertinoColors.white : AppColors.n100;
    }

    for (final b in _bars) {
      final barRect = Rect.fromLTWH(b[0] * s, b[1] * s, 9 * s, b[2] * s);
      canvas.drawRRect(
        RRect.fromRectAndRadius(barRect, Radius.circular(4.5 * s)),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.tile != tile || old.bars != bars;
}
