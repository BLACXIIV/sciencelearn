import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/shadows.dart';
import '../tokens/typography.dart';

/// RadioCard — a single selectable card tile: white, line border, radius 14,
/// 4px card edge. Selected = pastel-mint fill, 2px navy border, navy edge.
/// Compose inside DSRadioGroup for single-choice sets.
class DSRadioCard extends StatelessWidget {
  final bool selected;
  final VoidCallback? onSelect;
  final bool disabled;
  final Widget child;

  const DSRadioCard({
    super.key,
    required this.selected,
    this.onSelect,
    this.disabled = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final edge = selected ? DSColors.navy : DSColors.edgeCard;
    return GestureDetector(
      onTap: disabled ? null : onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? DSColors.pastelMint : DSColors.surface,
          borderRadius: DSRadii.inputBr,
          border: Border.all(
            color: selected ? DSColors.navy : DSColors.line,
            width: selected ? 2 : 1,
          ),
          boxShadow: dsEdge(edge, h: 4),
        ),
        child: Opacity(
          opacity: disabled ? 0.55 : 1,
          child: Center(
            child: DefaultTextStyle.merge(
              style: DSText.label.copyWith(fontSize: 14, color: DSColors.navy),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
