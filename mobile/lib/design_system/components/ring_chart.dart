import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/colors.dart';

class DSRingSlice {
  /// Fraction of the ring (values are normalized to their sum).
  final double value;

  /// Series 1–4 → DSColors.chart1..4 (lessons, quizzes, pre-test, post-test).
  final int series;
  const DSRingSlice(this.value, {this.series = 1});
}

/// RingChart — multi-series donut on a DSColors.track base ring. Series
/// colors come from chart tokens only so web and mobile rings match.
/// `center` renders inside the hole (big number + caption).
class DSRingChart extends StatelessWidget {
  final List<DSRingSlice> slices;
  final double size;
  final double thickness;
  final Widget? center;

  const DSRingChart({
    super.key,
    required this.slices,
    this.size = 84,
    this.thickness = 10,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(slices, thickness),
          ),
          if (center != null) center!,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final List<DSRingSlice> slices;
  final double thickness;
  _RingPainter(this.slices, this.thickness);

  static const _seriesColors = [
    DSColors.chart1, DSColors.chart2, DSColors.chart3, DSColors.chart4,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final r = (size.width - thickness) / 2;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: r);
    final track = Paint()
      ..color = DSColors.track
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    final total = slices.fold<double>(0, (s, x) => s + x.value);
    if (total <= 0) return;
    var start = -math.pi / 2;
    for (final s in slices) {
      final sweep = (s.value / total) * math.pi * 2;
      final paint = Paint()
        ..color = _seriesColors[(s.series - 1).clamp(0, 3)]
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round;
      // shrink each arc a hair so series don't overlap round caps
      canvas.drawArc(rect, start + 0.012, sweep - 0.024, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.slices != slices || old.thickness != thickness;
}
