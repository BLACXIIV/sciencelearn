import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';

/// Compact pill toggle — 44x26 track, 20px white knob, no Material halo.
/// On = [activeColor] (teal for publish/scored toggles), off = switchOff.
/// Disabled renders at 45% opacity.
class DSCompactSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool disabled;
  final Color activeColor;
  final String? semanticsLabel;

  const DSCompactSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.disabled = false,
    this.activeColor = DSColors.teal,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: Semantics(
        button: true,
        toggled: value,
        label: semanticsLabel,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: disabled ? null : () => onChanged?.call(!value),
          child: SizedBox(
            width: 44,
            height: 26,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: value ? activeColor : DSColors.switchOff,
                borderRadius: DSRadii.pillBr,
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 150),
                alignment: value
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: DSColors.surface,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
