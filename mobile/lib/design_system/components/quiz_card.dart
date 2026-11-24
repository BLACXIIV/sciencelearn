import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/shadows.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';
import 'chip.dart';

/// QuizCard — navy question panel (radius 32, navy-deep edge) with a pastel
/// category chip, white question text, and stacked options. Mirrors the
/// landing "quiz" demo and the web QuizCard.
class DSQuizCard extends StatelessWidget {
  /// Category pill (e.g. "Pre-test", "Chapter 3").
  final String? tag;
  final Widget title;
  final List<Widget> options;
  final Widget? footer;

  const DSQuizCard({
    super.key,
    this.tag,
    required this.title,
    required this.options,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DSSpacing.s6),
      decoration: BoxDecoration(
        color: DSColors.navy,
        borderRadius: DSRadii.panelBr,
        boxShadow: dsEdge(DSColors.edgeNavy),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tag != null)
            DSChip(variant: DSChipVariant.pastel, pastel: DSChipPastel.mint, child: Text(tag!)),
          if (tag != null) const SizedBox(height: DSSpacing.s4),
          DefaultTextStyle.merge(
            style: DSText.h3.copyWith(color: DSColors.surface),
            child: title,
          ),
          const SizedBox(height: DSSpacing.s4),
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(height: DSSpacing.s3),
            options[i],
          ],
          if (footer != null) ...[
            const SizedBox(height: DSSpacing.s4),
            DefaultTextStyle.merge(
              style: DSText.caption.copyWith(color: DSColors.pastelBlue, fontWeight: FontWeight.w500),
              child: footer!,
            ),
          ],
        ],
      ),
    );
  }
}
