import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/shadows.dart';
import '../tokens/typography.dart';
import 'card.dart';

/// StickerBadge — the tilted pastel sticker: white (or pastel) fill,
/// radius 12, Lexend 800/13, 4px black@20% edge, slightly rotated
/// (audit: −5° / +5°). For decorative labels over hero art and auth
/// panels — not for status.
class DSStickerBadge extends StatelessWidget {
  /// Resting rotation in degrees. Default −5.
  final double rotation;

  /// Pastel fill; the default sticker is white.
  final DSCardPastel? pastel;
  final Widget child;

  const DSStickerBadge(
      {super.key, this.rotation = -5, this.pastel, required this.child});

  @override
  Widget build(BuildContext context) {
    final bg = switch (pastel) {
      DSCardPastel.blue => DSColors.pastelBlue,
      DSCardPastel.yellow => DSColors.pastelYellow,
      DSCardPastel.purple => DSColors.pastelPurple,
      DSCardPastel.mint => DSColors.pastelMint,
      null => DSColors.surface,
    };
    return Transform.rotate(
      angle: rotation * 3.141592653589793 / 180,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: dsEdge(DSColors.edgeChip, h: 4),
        ),
        child: DefaultTextStyle.merge(
          style: DSText.label.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: DSColors.navy,
          ),
          child: child,
        ),
      ),
    );
  }
}
