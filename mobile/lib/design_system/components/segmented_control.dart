import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/typography.dart';

class DSSegment {
  final String value;
  final String label;
  const DSSegment(this.value, this.label);
}

/// SegmentedControl — white track + navy sliding pill (the Log in / Sign up
/// switcher). Track: radius 16, line border. Pill slides via AnimatedAlign
/// (200ms ease). Use for the top-level mode switch only.
class DSSegmentedControl extends StatelessWidget {
  final List<DSSegment> options;
  final String value;
  final ValueChanged<String> onChanged;

  const DSSegmentedControl({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final idx = options.indexWhere((o) => o.value == value).clamp(0, options.length - 1);
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DSColors.surface,
        borderRadius: DSRadii.buttonBr,
        border: Border.all(color: DSColors.line),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth / options.length;
          return Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment: Alignment(-1 + 2 * idx / (options.length - 1), 0),
                child: Container(
                  width: w,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: DSColors.navy,
                    borderRadius: DSRadii.chipBr,
                  ),
                ),
              ),
              Row(
                children: [
                  for (final o in options)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(o.value),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: DSText.label.copyWith(
                              fontSize: 14,
                              color: o.value == value ? DSColors.surface : DSColors.muted,
                            ),
                            child: Text(o.label),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
