import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/shadows.dart';
import '../tokens/typography.dart';
import 'icon.dart';

enum DSQuizOptionState { normal, selected, correct, wrong, disabled }

/// QuizOption — the answer row: white, 5px edge, navy letter badge.
/// selected = blue border + pastel-blue fill; correct = mint fill + teal edge;
/// wrong = coral surface; disabled = faded, no edge. Whole row is a button.
class DSQuizOption extends StatefulWidget {
  /// A–D letter badge.
  final String letter;
  final DSQuizOptionState state;
  final VoidCallback? onTap;
  final Widget child;

  const DSQuizOption({
    super.key,
    required this.letter,
    this.state = DSQuizOptionState.normal,
    this.onTap,
    required this.child,
  });

  @override
  State<DSQuizOption> createState() => _DSQuizOptionState();
}

class _DSQuizOptionState extends State<DSQuizOption> {
  bool _pressed = false;
  bool get _inactive =>
      widget.state == DSQuizOptionState.disabled || widget.onTap == null;

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final (fill, border, borderW, edge, badge) = switch (s) {
      DSQuizOptionState.selected => (
          DSColors.pastelBlue,
          DSColors.blue,
          2.0,
          DSColors.edgeBlue,
          DSColors.navy
        ),
      DSQuizOptionState.correct => (
          DSColors.pastelMint,
          DSColors.success,
          2.0,
          DSColors.edgeMint,
          DSColors.success
        ),
      DSQuizOptionState.wrong => (
          DSColors.errorSurface,
          DSColors.error,
          2.0,
          DSColors.error,
          DSColors.error
        ),
      _ => (
          DSColors.surface,
          Colors.transparent,
          2.0,
          DSColors.edgeWhite,
          DSColors.navy
        ),
    };
    final mark = s == DSQuizOptionState.correct
        ? DSIconName.check
        : s == DSQuizOptionState.wrong
            ? DSIconName.close
            : null;

    return GestureDetector(
      onTapDown: (_) {
        if (!_inactive) setState(() => _pressed = true);
      },
      onTapUp: (_) {
        if (_pressed) setState(() => _pressed = false);
      },
      onTapCancel: () {
        if (_pressed) setState(() => _pressed = false);
      },
      onTap: _inactive ? null : widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.translationValues(0, _pressed ? 4 : 0, 0),
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: DSRadii.buttonBr,
          border: Border.all(color: border, width: borderW),
          boxShadow: s == DSQuizOptionState.disabled
              ? const []
              : dsEdge(edge, h: _pressed ? 1 : 5),
        ),
        child: Opacity(
          opacity: s == DSQuizOptionState.disabled ? 0.5 : 1,
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration:
                    BoxDecoration(color: badge, borderRadius: DSRadii.chipBr),
                child: Center(
                  child: Text(
                    widget.letter,
                    style: DSText.button.copyWith(color: DSColors.surface),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DefaultTextStyle.merge(
                  style:
                      DSText.label.copyWith(fontSize: 14, color: DSColors.navy),
                  child: widget.child,
                ),
              ),
              if (mark != null) ...[
                const SizedBox(width: 12),
                DSIcon(mark, size: 20, color: badge),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
