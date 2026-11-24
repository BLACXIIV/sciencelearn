import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/typography.dart';

/// Switch — pill toggle. Track goes blue when on; row target ≥44px.
class DSSwitch extends StatelessWidget {
  final String? label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool disabled;

  const DSSwitch({
    super.key,
    this.label,
    required this.value,
    this.onChanged,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final sw = Switch(
      value: value,
      onChanged: disabled ? null : onChanged,
      activeThumbColor: DSColors.surface,
      activeTrackColor: DSColors.blue,
      inactiveThumbColor: DSColors.surface,
      inactiveTrackColor: DSColors.track,
      trackOutlineColor: const WidgetStatePropertyAll(DSColors.line),
    );
    if (label == null) return sw;
    return InkWell(
      onTap: disabled ? null : () => onChanged?.call(!value),
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            sw,
            const SizedBox(width: 12),
            Flexible(child: Text(label!, style: DSText.bodySm.copyWith(color: DSColors.inkSoft))),
          ],
        ),
      ),
    );
  }
}
