import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/shadows.dart';
import '../tokens/typography.dart';

/// DSFlashcard — tap to flip between front (paper) and back (pastel mint).
/// Exposes itself as a button to a11y; honors reduced motion via
/// MediaQuery.disableAnimationsOf (swaps instantly, no 3D animation).
class DSFlashcard extends StatefulWidget {
  /// Question side — shown first.
  final Widget front;

  /// Answer side — revealed on flip.
  final Widget back;
  const DSFlashcard({super.key, required this.front, required this.back});

  @override
  State<DSFlashcard> createState() => _DSFlashcardState();
}

class _DSFlashcardState extends State<DSFlashcard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 450));
  bool _flipped = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _flip(bool reduceMotion) {
    setState(() => _flipped = !_flipped);
    if (reduceMotion) {
      _ctrl.value = _flipped ? 1 : 0;
    } else {
      _flipped ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      label: _flipped
          ? 'Flashcard, answer side. Activate to show the question.'
          : 'Flashcard, question side. Activate to show the answer.',
      child: GestureDetector(
        onTap: () => _flip(reduceMotion),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final angle = _ctrl.value * 3.1415926535;
            final showBack = angle > 3.1415926535 / 2;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateY(showBack ? angle - 3.1415926535 : angle),
              child: _Face(
                pastel: showBack,
                child: showBack ? widget.back : widget.front,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Face extends StatelessWidget {
  final bool pastel;
  final Widget child;
  const _Face({required this.pastel, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 96),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pastel ? DSColors.pastelMint : DSColors.surface,
        borderRadius: DSRadii.cardBr,
        boxShadow: dsEdge(pastel ? DSColors.edgeMint : DSColors.edgeCard, h: 5),
      ),
      child: DefaultTextStyle(
        style: DSText.body,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            child,
            if (!pastel)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Tap to flip',
                      style: DSText.caption.copyWith(color: DSColors.muted)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
