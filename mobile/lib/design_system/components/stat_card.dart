import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/shadows.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';
import 'card.dart';
import 'icon.dart';

enum DSStatPastel { blue, yellow, purple, mint }

/// StatCard — chunky dashboard stat tile. Default: white card + pastel icon
/// square + big value + caption. `filled` makes the whole card pastel with a
/// white icon square (teacher portal tiles). `alert` gives the white card a
/// sun border for action-needed tiles. `note` is the small reason line under
/// the label; `action` renders a control at the card foot.
class DSStatCard extends StatelessWidget {
  final DSIconName icon;
  final String value;
  final String label;
  final DSStatPastel pastel;
  final bool filled;
  final String? note;
  final bool alert;
  final Widget? action;

  const DSStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.pastel = DSStatPastel.blue,
    this.filled = false,
    this.note,
    this.alert = false,
    this.action,
  });

  Color get _pastelColor => switch (pastel) {
        DSStatPastel.blue => DSColors.pastelBlue,
        DSStatPastel.yellow => DSColors.pastelYellow,
        DSStatPastel.purple => DSColors.pastelPurple,
        DSStatPastel.mint => DSColors.pastelMint,
      };

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: filled ? DSColors.surface : _pastelColor,
            borderRadius: DSRadii.inputBr,
          ),
          child: Center(child: DSIcon(icon, size: 22, color: DSColors.navy)),
        ),
        Text(value,
            style: DSText.h3.copyWith(fontSize: 26, color: DSColors.navy)),
        Text(label,
            style: DSText.bodySm.copyWith(
                fontWeight: FontWeight.w600, color: DSColors.inkSoft)),
        if (note != null)
          Text(note!, style: DSText.caption.copyWith(color: DSColors.muted)),
        if (action != null)
          Padding(padding: const EdgeInsets.only(top: 8), child: action!),
      ],
    );

    if (filled) {
      return DSCard(
        variant: DSCardVariant.pastel,
        pastel: switch (pastel) {
          DSStatPastel.blue => DSCardPastel.blue,
          DSStatPastel.yellow => DSCardPastel.yellow,
          DSStatPastel.purple => DSCardPastel.purple,
          DSStatPastel.mint => DSCardPastel.mint,
        },
        padding: const EdgeInsets.all(DSSpacing.s4),
        child: content,
      );
    }
    if (alert) {
      // Action-needed tile: white card + 3px sun border (pending request).
      return Container(
        padding: const EdgeInsets.all(DSSpacing.s4),
        decoration: BoxDecoration(
          color: DSColors.surface,
          borderRadius: DSRadii.cardBr,
          border: Border.all(color: DSColors.sun, width: 3),
          boxShadow: dsEdge(DSColors.edgeCard, h: 6),
        ),
        child: content,
      );
    }
    return DSCard(
      padding: const EdgeInsets.all(DSSpacing.s4),
      child: content,
    );
  }
}
