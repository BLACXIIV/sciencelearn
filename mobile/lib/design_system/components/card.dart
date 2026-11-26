import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/shadows.dart';
import '../tokens/spacing.dart';

enum DSCardVariant { white, pastel, navy, trivia, flat }

enum DSCardPastel { blue, yellow, purple, mint }

/// Card — the chunky content card. Variants:
/// - white:  white fill, 6px card edge (default)
/// - pastel: pastel fill + matching edge, use `pastel`
/// - navy:   navy fill, navy-deep edge — white text
/// - trivia: white fill, 5px card edge, −1.2° resting tilt ("Did you know?")
/// - flat:   white fill, 1px line border, no edge
/// `tilt` applies the ±1.2° resting tilt (touch has no hover to flatten).
class DSCard extends StatelessWidget {
  final DSCardVariant variant;
  final DSCardPastel pastel;
  final bool tilt;

  /// Resting tilt of −1.2° instead of +1.2° (alternating mission cards).
  final bool tiltLeft;
  final EdgeInsetsGeometry? padding;
  final Widget child;

  const DSCard({
    super.key,
    this.variant = DSCardVariant.white,
    this.pastel = DSCardPastel.blue,
    this.tilt = false,
    this.tiltLeft = false,
    this.padding,
    required this.child,
  });

  (Color, List<BoxShadow>, Border?, double) _style() => switch (variant) {
        // (fill, shadow, border, tiltDeg)
        DSCardVariant.white => (
            DSColors.surface,
            dsEdge(DSColors.edgeCard),
            null,
            0.0
          ),
        DSCardVariant.pastel => switch (pastel) {
            DSCardPastel.blue => (
                DSColors.pastelBlue,
                dsEdge(DSColors.edgeWhite),
                null,
                0.0
              ),
            DSCardPastel.yellow => (
                DSColors.pastelYellow,
                dsEdge(DSColors.edgeCard),
                null,
                0.0
              ),
            DSCardPastel.purple => (
                DSColors.pastelPurple,
                dsEdge(DSColors.edgeCard),
                null,
                0.0
              ),
            DSCardPastel.mint => (
                DSColors.pastelMint,
                dsEdge(DSColors.edgeMint),
                null,
                0.0
              ),
          },
        DSCardVariant.navy => (
            DSColors.navy,
            dsEdge(DSColors.edgeNavy),
            null,
            0.0
          ),
        DSCardVariant.trivia => (
            DSColors.surface,
            dsEdge(DSColors.edgeCard, h: 5),
            null,
            -1.2
          ),
        DSCardVariant.flat => (
            DSColors.surface,
            const <BoxShadow>[],
            Border.all(color: DSColors.line),
            0.0,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final (fill, shadow, border, restTilt) = _style();
    final deg = tilt
        ? 1.2
        : tiltLeft
            ? -1.2
            : restTilt;
    final card = Container(
      padding: padding ?? const EdgeInsets.all(DSSpacing.s5),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: DSRadii.cardBr,
        border: border,
        boxShadow: shadow,
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(
            color: variant == DSCardVariant.navy
                ? DSColors.surface
                : DSColors.ink),
        child: child,
      ),
    );
    // Transform pushes a compositing layer — skip it at 0° so flat cards
    // don't pay a layer each per scroll frame.
    return deg == 0
        ? card
        : Transform.rotate(angle: deg * 3.141592653589793 / 180, child: card);
  }
}
