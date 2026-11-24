import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/typography.dart';
import 'icon.dart';

class DSSelectOption {
  final String value;
  final String label;
  const DSSelectOption(this.value, this.label);
}

/// Labeled dropdown — styled DropdownButtonFormField on the shared field
/// chrome (radius 14, blue focus) with a chevron affordance. For 2–4
/// prominent choices prefer DSRadioGroup or DSOptionTile.
class DSSelect extends StatelessWidget {
  final String label;
  final List<DSSelectOption> options;
  final String? value;
  final ValueChanged<String?>? onChanged;
  final String? error;
  final String? helper;

  const DSSelect({
    super.key,
    required this.label,
    required this.options,
    this.value,
    this.onChanged,
    this.error,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: DSText.label),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          onChanged: onChanged,
          icon: const DSIcon(DSIconName.chevron, size: 18, color: DSColors.muted),
          style: DSText.bodySm.copyWith(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            errorText: error,
            helperText: error == null ? helper : null,
          ),
          items: [
            for (final o in options)
              DropdownMenuItem(value: o.value, child: Text(o.label)),
          ],
        ),
      ],
    );
  }
}
