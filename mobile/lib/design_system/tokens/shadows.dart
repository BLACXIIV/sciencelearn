import 'package:flutter/material.dart';

/// ScienceLearn Design System — elevation: the "edge" model.
/// Solid bottom edge only — a darker shade of the fill, offset down, NO blur.
/// Heights 3–6 are the surface scale; 1–2 are pressed/active states (the edge
/// "recedes" under the finger). Colors come from DSColors.edge*.
/// Matches edge(color, height) in web/src/design-system/tokens/shadows.css.
List<BoxShadow> dsEdge(Color color, {int h = 6}) {
  assert(
      h >= 1 && h <= 6, 'edge height must be 1-6 (3-6 surfaces, 1-2 pressed)');
  return [BoxShadow(color: color, offset: Offset(0, h.toDouble()))];
}

/// Solid TOP edge — same model flipped: for surfaces whose leading edge is
/// at the top (the auth sheet's mint crown). Heights 3–6, still no blur.
List<BoxShadow> dsEdgeTop(Color color, {int h = 3}) {
  assert(h >= 3 && h <= 6, 'edge height must be 3, 4, 5 or 6');
  return [BoxShadow(color: color, offset: Offset(0, -h.toDouble()))];
}

/// Soft upward drop shadow — the sticky bottom bar lifting off the page.
/// Mirrors web `--ds-shadow-bar`: 0 -4px 16px navy at 12%.
List<BoxShadow> dsBarLift() => [
      BoxShadow(
        color: const Color(0xFF0A1A5C).withValues(alpha: 0.12),
        offset: const Offset(0, -4),
        blurRadius: 16,
      ),
    ];
