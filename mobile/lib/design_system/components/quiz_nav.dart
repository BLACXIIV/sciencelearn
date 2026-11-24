import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/shadows.dart';
import '../tokens/typography.dart';

enum DSQuizDotState { current, answered, unanswered }

/// DSQuizNav — numbered dots for jumping between quiz questions.
/// States: current (navy), answered (pastel mint), unanswered (hollow dash).
class DSQuizNav extends StatelessWidget {
  final int count;
  final int current;
  final List<bool> answered;
  final ValueChanged<int> onSelect;
  const DSQuizNav({
    super.key,
    required this.count,
    required this.current,
    required this.answered,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < count; i++)
          _Dot(
            index: i,
            state: i == current
                ? DSQuizDotState.current
                : (i < answered.length && answered[i])
                    ? DSQuizDotState.answered
                    : DSQuizDotState.unanswered,
            onTap: () => onSelect(i),
          ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final int index;
  final DSQuizDotState state;
  final VoidCallback onTap;
  const _Dot({required this.index, required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, edge, border) = switch (state) {
      DSQuizDotState.current => (
          DSColors.navy,
          DSColors.paper,
          DSColors.edgeNavy,
          Border.all(color: DSColors.navy),
        ),
      DSQuizDotState.answered => (
          DSColors.pastelMint,
          DSColors.navy,
          DSColors.edgeMint,
          Border.all(color: DSColors.pastelMint),
        ),
      DSQuizDotState.unanswered => (
          DSColors.surface,
          DSColors.muted,
          DSColors.edgeCard,
          Border.all(color: DSColors.line, style: BorderStyle.solid),
        ),
    };
    return Semantics(
      button: true,
      label: 'Question ${index + 1}${switch (state) {
        DSQuizDotState.current => ', current',
        DSQuizDotState.answered => ', answered',
        DSQuizDotState.unanswered => ', unanswered',
      }}',
      child: InkWell(
        onTap: onTap,
        borderRadius: DSRadii.buttonBr,
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            border: border,
            borderRadius: DSRadii.buttonBr,
            boxShadow: dsEdge(edge, h: 2),
          ),
          child: Text('${index + 1}',
              style: DSText.label.copyWith(color: fg, fontSize: 13)),
        ),
      ),
    );
  }
}
