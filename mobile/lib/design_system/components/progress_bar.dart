import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';

enum DSProgressBarSize { lg, sm }
enum DSProgressBarTone { blue, mint, sun, success }

/// ProgressBar — track + fill, radius 99. Sizes: lg 14px / sm 10px only.
/// Track is DSColors.track; tone sets the fill color.
class DSProgressBar extends StatelessWidget {
  /// 0–1.
  final double value;
  final DSProgressBarSize size;
  final DSProgressBarTone tone;

  const DSProgressBar({
    super.key,
    required this.value,
    this.size = DSProgressBarSize.lg,
    this.tone = DSProgressBarTone.blue,
  });

  @override
  Widget build(BuildContext context) {
    final h = size == DSProgressBarSize.lg ? 14.0 : 10.0;
    final fill = switch (tone) {
      DSProgressBarTone.blue => DSColors.blue,
      DSProgressBarTone.mint => DSColors.mint,
      DSProgressBarTone.sun => DSColors.sun,
      DSProgressBarTone.success => DSColors.success,
    };
    return Semantics(
      label: 'Progress ${(value.clamp(0, 1) * 100).round()}%',
      child: Container(
        height: h,
        decoration: BoxDecoration(
          color: DSColors.track,
          borderRadius: DSRadii.pillBr,
        ),
        clipBehavior: Clip.antiAlias,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(color: fill, borderRadius: DSRadii.pillBr),
          ),
        ),
      ),
    );
  }
}
