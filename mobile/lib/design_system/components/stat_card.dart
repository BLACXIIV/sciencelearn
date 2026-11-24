import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';
import 'card.dart';
import 'icon.dart';

enum DSStatPastel { blue, yellow, purple, mint }

/// StatCard — white card: pastel icon square + big Lexend value + caption.
/// For dashboard stat rows. Icon must come from the registry (never emoji).
class DSStatCard extends StatelessWidget {
  final DSIconName icon;
  final String value;
  final String label;
  final DSStatPastel pastel;

  const DSStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.pastel = DSStatPastel.blue,
  });

  @override
  Widget build(BuildContext context) {
    final icBg = switch (pastel) {
      DSStatPastel.blue => DSColors.pastelBlue,
      DSStatPastel.yellow => DSColors.pastelYellow,
      DSStatPastel.purple => DSColors.pastelPurple,
      DSStatPastel.mint => DSColors.pastelMint,
    };
    return DSCard(
      padding: const EdgeInsets.all(DSSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(color: icBg, borderRadius: DSRadii.inputBr),
            child: Center(child: DSIcon(icon, size: 22, color: DSColors.navy)),
          ),
          Text(value, style: DSText.h3.copyWith(fontSize: 24, color: DSColors.navy)),
          Text(label, style: DSText.caption.copyWith(color: DSColors.muted)),
        ],
      ),
    );
  }
}
