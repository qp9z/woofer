import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';

/// The WOOFER canvas: a near-vertical dark gradient with four blurred blurple/
/// rose blobs slowly drifting — the design's motion signature. Blobs are soft
/// RadialGradients (their falloff stands in for the 48px blur), animated with a
/// single controller, so this stays cheap: no per-frame BackdropFilter.
class AuroraBackground extends StatefulWidget {
  final Widget child;
  const AuroraBackground({super.key, required this.child});

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();

  // color, alpha, w%, h%, and edge anchors (fractions of the screen). One of
  // left/right and one of top/bottom is set per blob; phase staggers the drift.
  static const _blobs = <_Blob>[
    _Blob(AppColors.blobA, 0.50, 0.70, 0.38, left: -0.18, top: -0.12, phase: 0.0),
    _Blob(AppColors.blobB, 0.42, 0.64, 0.40, right: -0.24, top: 0.26, phase: -0.286),
    _Blob(AppColors.blobC, 0.32, 0.74, 0.34, left: 0.08, bottom: 0.06, phase: -0.571),
    _Blob(AppColors.blobD, 0.30, 0.52, 0.30, right: -0.10, bottom: -0.14, phase: -0.786),
  ];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: _bgGradient),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return Stack(
            children: [
              AnimatedBuilder(
                animation: _c,
                builder: (context, _) => Stack(
                  children: [for (final b in _blobs) b.build(w, h, _c.value)],
                ),
              ),
              Positioned.fill(child: widget.child),
            ],
          );
        },
      ),
    );
  }

  // 170° ≈ near-vertical top→bottom.
  static const _bgGradient = LinearGradient(
    begin: Alignment(-0.17, -1),
    end: Alignment(0.17, 1),
    colors: [AppColors.auroraA, AppColors.auroraB, AppColors.auroraC],
    stops: [0.0, 0.42, 1.0],
  );
}

class _Blob {
  final Color color;
  final double alpha, wFrac, hFrac, phase;
  final double? left, right, top, bottom;
  const _Blob(this.color, this.alpha, this.wFrac, this.hFrac,
      {this.left, this.right, this.top, this.bottom, required this.phase});

  Widget build(double w, double h, double t) {
    // Smooth 0→1→0 easing over the period; drives translate + scale.
    final k = (1 - math.cos(2 * math.pi * (t + phase))) / 2;
    final dx = -0.04 * k * w;
    final dy = 0.03 * k * h;
    final scale = 1 + 0.08 * k;

    return Positioned(
      width: w * wFrac,
      height: h * hFrac,
      left: left == null ? null : left! * w + dx,
      right: right == null ? null : right! * w - dx,
      top: top == null ? null : top! * h + dy,
      bottom: bottom == null ? null : bottom! * h - dy,
      child: Transform.scale(
        scale: scale,
        child: IgnorePointer(
          child: DecoratedBox(
            // No explicit shape: the RadialGradient fills the (non-square) box as
            // an ellipse and fades to transparent — the blob's soft falloff.
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
