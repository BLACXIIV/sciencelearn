import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import 'icon.dart';
import 'text_field.dart';

/// SearchField — DSTextField with a leading search icon and search keyboard.
/// Use for filtering lists (students, classes, lessons).
class DSSearchField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  const DSSearchField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DSTextField(
      label: label,
      hint: hint,
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.text,
      leading: const Padding(
        padding: EdgeInsets.only(left: 14, right: 8),
        child: DSIcon(DSIconName.search, size: 18, color: DSColors.muted),
      ),
    );
  }
}
