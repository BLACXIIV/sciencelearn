import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/shadows.dart';
import '../tokens/typography.dart';

/// StickerBadge — the tilted pastel sticker: white fill, radius 12, Lexend
/// 800/13, 4px black@20% edge, slightly rotated (audit: −5° / +5°).
/// For decorative labels over hero art and auth panels — not for status.
class DSStickerBadge extends StatelessWidget {
  /// Resting rotation in degrees. Default −5.
  final double rotation;
  final Widget child;

  const DSStickerBadge({super.key, this.rotation = -5, required this.child});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation * 3.141592653589793 / 180,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: DSColors.surface,
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
