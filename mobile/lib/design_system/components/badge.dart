import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/typography.dart';

enum DSBadgeTone { blue, mint, sun, error }

/// Badge — tiny count/status pill (radius 99, Lexend 800/11). For counts on
/// nav items, avatars and cards — not clickable.
class DSBadge extends StatelessWidget {
  final DSBadgeTone tone;
  final Widget child;

  const DSBadge({super.key, this.tone = DSBadgeTone.blue, required this.child});

  @override
  Widget build(BuildContext context) {
    final (fill, text) = switch (tone) {
      DSBadgeTone.blue => (DSColors.blue, DSColors.surface),
      DSBadgeTone.mint => (DSColors.mint, DSColors.navy),
      DSBadgeTone.sun => (DSColors.sun, DSColors.navy),
      DSBadgeTone.error => (DSColors.error, DSColors.surface),
    };
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(color: fill, borderRadius: DSRadii.pillBr),
      child: DefaultTextStyle.merge(
        style: DSText.label
            .copyWith(fontSize: 11, fontWeight: FontWeight.w800, color: text),
        textAlign: TextAlign.center,
        child: child,
      ),
    );
  }
}
