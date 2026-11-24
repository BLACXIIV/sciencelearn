import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/shadows.dart';
import '../tokens/spacing.dart';

/// Panel — the big navy surface (radius 32, navy-deep edge, white text):
/// quiz cards, hero dark panels, call-to-action bands.
class DSPanel extends StatelessWidget {
  final EdgeInsetsGeometry? padding;
  final Widget child;

  const DSPanel({super.key, this.padding, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(DSSpacing.s6),
      decoration: BoxDecoration(
        color: DSColors.navy,
        borderRadius: DSRadii.panelBr,
        boxShadow: dsEdge(DSColors.edgeNavy),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: DSColors.surface),
        child: child,
      ),
    );
  }
}
