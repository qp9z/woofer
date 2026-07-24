import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';

/// The WOOFER logo mark: five vertical bars rising to a center peak
/// (equalizer/waveform) on an optional rounded tile. Geometry matches the
/// brand SVG exactly (100×100 viewBox), so it scales cleanly at any size.
///
/// Dependency-free (a CustomPainter, no flutter_svg): the mark is just five
/// rounded rects, cheaper to draw than to parse an SVG.
///
/// Set [animated] for the brand `eq` motion — bars pulsing scaleY 0.28↔1 over
/// 1.1s with a symmetric 0.14s stagger (THEME.md → Motion).
enum WooferTile { accent, dark, none }

enum WooferBars { light, accent }

class WooferMark extends StatefulWidget {
  final double size;
  final WooferTile tile;
  final WooferBars bars;
  final bool animated;

  const WooferMark({
    super.key,
    required this.size,
    this.tile = WooferTile.accent,
    this.bars = WooferBars.light,
    this.animated = false,
  });

  @override
  State<WooferMark> createState() => _WooferMarkState();
}

class _WooferMarkState extends State<WooferMark> with SingleTickerProviderStateMixin {
  AnimationController? _c;

  @override
  void initState() {
    super.initState();
    if (widget.animated) _start();
  }

  void _start() {
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat();
  }

  @override
  void didUpdateWidget(WooferMark old) {
    super.didUpdateWidget(old);
    if (widget.animated && _c == null) {
      _start();
    } else if (!widget.animated && _c != null) {
      _c!.dispose();
      _c = null;
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _c;
    if (controller == null) {
      return CustomPaint(
        size: Size.square(widget.size),
        painter: _MarkPainter(tile: widget.tile, bars: widget.bars),
      );
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => CustomPaint(
        size: Size.square(widget.size),
        painter: _MarkPainter(tile: widget.tile, bars: widget.bars, beat: controller.value),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  final WooferTile tile;
  final WooferBars bars;

  /// 0→1 loop position driving the equalizer pulse; null paints the static mark.
  final double? beat;

  const _MarkPainter({required this.tile, required this.bars, this.beat});

  // x, y, height on the 100×100 grid (width 9, rx 4.5 for every bar). Every bar
  // is centred on y=50, so the pulse scales about that line and stays symmetric.
  static const _bars = <List<double>>[
    [11.5, 36.55, 26.9],
    [28.5, 27.0, 46.0],
    [45.5, 18.0, 64.0],
    [62.5, 27.0, 46.0],
    [79.5, 36.55, 26.9],
  ];

  /// Symmetric stagger (0 / 0.14 / 0.28 / 0.14 / 0 s) as a fraction of the 1.1s loop.
  static const _delays = <double>[0, 0.127, 0.255, 0.127, 0];

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

    for (var i = 0; i < _bars.length; i++) {
      var y = _bars[i][1];
      var h = _bars[i][2];
      if (beat != null) {
        // Ease-in-out 0→1→0 over the loop, offset per bar for the stagger.
        final phase = (beat! + _delays[i]) % 1.0;
        final k = (1 - math.cos(2 * math.pi * phase)) / 2;
        final center = y + h / 2;
        h *= 0.28 + 0.72 * k;
        y = center - h / 2;
      }
      final barRect = Rect.fromLTWH(_bars[i][0] * s, y * s, 9 * s, h * s);
      canvas.drawRRect(
        RRect.fromRectAndRadius(barRect, Radius.circular(4.5 * s)),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.tile != tile || old.bars != bars || old.beat != beat;
}
