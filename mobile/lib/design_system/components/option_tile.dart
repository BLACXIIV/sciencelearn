import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/shadows.dart';
import '../tokens/typography.dart';
import 'icon.dart';

/// OptionTile — the 52px selectable tile used by the sign-up role picker
/// (icon + label, mint when chosen). Use DSRadioCard/DSRadioGroup when you
/// need group semantics; OptionTile is the visual tile for standalone toggles.
class DSOptionTile extends StatelessWidget {
  final DSIconName? icon;
  final String label;
  final bool selected;

  /// Pastel fill when selected. Default pastelMint (role picker uses
  /// pastelMint for Student, pastelYellow for Teacher).
  final Color selectedFill;
  final bool disabled;
  final VoidCallback? onTap;

  const DSOptionTile({
    super.key,
    this.icon,
    required this.label,
    this.selected = false,
    this.selectedFill = DSColors.pastelMint,
    this.disabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final edge = selected ? DSColors.navy : DSColors.edgeCard;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? selectedFill : DSColors.surface,
          borderRadius: DSRadii.inputBr,
          border: Border.all(
            color: selected ? DSColors.navy : DSColors.line,
            width: selected ? 2 : 1,
          ),
          boxShadow: dsEdge(edge, h: 4),
        ),
        child: Opacity(
          opacity: disabled ? 0.55 : 1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                DSIcon(icon!, size: 20, color: DSColors.navy),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  label,
                  style: DSText.label.copyWith(fontSize: 14, color: DSColors.navy),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
