import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/typography.dart';

/// Checkbox — accent-blue box + Inter label; whole row is a ≥44px target.
class DSCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool disabled;

  const DSCheckbox({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : () => onChanged?.call(!value),
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: value,
              onChanged: disabled ? null : (v) => onChanged?.call(v ?? false),
              activeColor: DSColors.blue,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(label,
                  style: DSText.bodySm.copyWith(color: DSColors.inkSoft)),
            ),
          ],
        ),
      ),
    );
  }
}
