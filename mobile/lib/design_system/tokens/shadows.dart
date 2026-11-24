import 'package:flutter/material.dart';

/// ScienceLearn Design System — elevation: the "edge" model.
/// Solid bottom edge only — a darker shade of the fill, offset down, NO blur.
/// Allowed heights: 3, 4, 5, 6. Colors come from DSColors.edge*.
/// Matches edge(color, height) in web/src/design-system/tokens/shadows.css.
List<BoxShadow> dsEdge(Color color, {int h = 6}) {
  assert(h >= 3 && h <= 6, 'edge height must be 3, 4, 5 or 6');
  return [BoxShadow(color: color, offset: Offset(0, h.toDouble()))];
}
