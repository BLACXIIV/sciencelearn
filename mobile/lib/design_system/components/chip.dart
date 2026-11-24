import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/shadows.dart';
import '../tokens/typography.dart';

enum DSChipVariant { white, pastel, navy, mint }
enum DSChipPastel { blue, yellow, purple, mint }

/// Chip — small pill label (radius 99) for tags and quiz-type markers.
/// White variant carries the 3px card edge like the landing type pills.
class DSChip extends StatelessWidget {
  final DSChipVariant variant;
  final DSChipPastel pastel;
  final Widget child;

  const DSChip({
    super.key,
    this.variant = DSChipVariant.white,
    this.pastel = DSChipPastel.blue,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final (fill, text, shadow) = switch (variant) {
      DSChipVariant.white => (DSColors.surface, DSColors.navy, dsEdge(DSColors.edgeCard, h: 3)),
      DSChipVariant.navy => (DSColors.navy, DSColors.surface, const <BoxShadow>[]),
      DSChipVariant.mint => (DSColors.mint, DSColors.navy, const <BoxShadow>[]),
      DSChipVariant.pastel => (switch (pastel) {
          DSChipPastel.blue => DSColors.pastelBlue,
          DSChipPastel.yellow => DSColors.pastelYellow,
          DSChipPastel.purple => DSColors.pastelPurple,
          DSChipPastel.mint => DSColors.pastelMint,
        }, DSColors.navy, const <BoxShadow>[]),
    };
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: DSRadii.pillBr,
        boxShadow: shadow,
      ),
      child: DefaultTextStyle.merge(
        style: DSText.label.copyWith(fontSize: 12, letterSpacing: 0.3, color: text),
        child: IconTheme.merge(
          data: IconThemeData(size: 14, color: text),
          child: child,
        ),
      ),
    );
  }
}
