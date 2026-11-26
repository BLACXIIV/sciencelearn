import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/colors.dart';

/// DSLoadingIndicator — the ScienceLearn atom: a navy nucleus with three
/// electrons (blue / teal / sun) travelling tilted elliptical orbits, each
/// leaving a short fading trail so the motion reads as orbiting, not a
/// spinner. Drop-in for CircularProgressIndicator:
///   const Center(child: DSLoadingIndicator())
///
/// Honors MediaQuery.disableAnimations — renders the atom parked on its
/// orbits instead of animating.
class DSLoadingIndicator extends StatefulWidget {
  /// Square edge in px. 48 covers a full-page loader; ~28 fits inline rows.
  final double size;
  const DSLoadingIndicator({super.key, this.size = 48});

  @override
  State<DSLoadingIndicator> createState() => _DSLoadingIndicatorState();
}

class _DSLoadingIndicatorState extends State<DSLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduced) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) =>
              CustomPaint(painter: _AtomPainter(_c.value)),
        ),
      ),
    );
  }
}

/// Paints the atom: 3 orbits rotated 0°/+60°/−60° (the logo's geometry),
/// nucleus at center, one electron per orbit at a parametric angle
/// θ = 2π·(t + phase). Three shrinking, fading dots trail each electron.
class _AtomPainter extends CustomPainter {
  final double t;
  const _AtomPainter(this.t);

  static const _tilts = [0.0, math.pi / 3, -math.pi / 3];
  static const _electronColors = [DSColors.blue, DSColors.teal, DSColors.sun];
  static const _trailAlphas = [0.42, 0.22, 0.10];
  static const _trailScales = [0.78, 0.58, 0.40];

  @override
  void paint(Canvas canvas, Size size) {
    final half = size.shortestSide / 2;
    final c = Offset(size.width / 2, size.height / 2);
    final rx = half * 0.88;
    final ry = rx * 0.38;
    final eRadius = half * 0.11;

    final orbitPaint = Paint()
      ..color = DSColors.edgeWhite
      ..style = PaintingStyle.stroke
      ..strokeWidth = half * 0.06;
    final ringPaint = Paint()
      ..color = DSColors.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = half * 0.035;

    for (var i = 0; i < _tilts.length; i++) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(_tilts[i]);

      // Orbit path.
      canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
          orbitPaint);

      // Electron + trail — trail dots sit behind it on the orbit.
      final color = _electronColors[i];
      final theta = 2 * math.pi * (t + i / 3);
      for (var k = _trailAlphas.length; k >= 1; k--) {
        final a = theta - k * 0.30;
        canvas.drawCircle(
            Offset(rx * math.cos(a), ry * math.sin(a)),
            eRadius * _trailScales[k - 1],
            Paint()..color = color.withValues(alpha: _trailAlphas[k - 1]));
      }
      final p = Offset(rx * math.cos(theta), ry * math.sin(theta));
      canvas.drawCircle(p, eRadius + half * 0.02, ringPaint);
      canvas.drawCircle(p, eRadius, Paint()..color = color);

      canvas.restore();
    }

    // Nucleus — slightly chunky, the "proton" the electrons orbit.
    canvas.drawCircle(c, half * 0.17, Paint()..color = DSColors.navy);
    canvas.drawCircle(
        c.translate(-half * 0.05, -half * 0.05),
        half * 0.05,
        Paint()..color = DSColors.surface.withValues(alpha: 0.55));
  }

  @override
  bool shouldRepaint(_AtomPainter old) => old.t != t;
}
