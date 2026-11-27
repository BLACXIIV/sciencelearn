import 'package:flutter/material.dart';

import 'text_field.dart';

/// Multi-line text input — same chrome as DSTextField (radius 14, blue
/// focus, error state), minimum ~4 lines tall.
class DSTextArea extends StatelessWidget {
  final String label;
  final String? hint;
  final String? error;
  final String? helper;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final int minLines;
  /// Normalize pasted/typed text live (docx symbol glyphs, arrows, subscripts).
  final bool clean;

  const DSTextArea({
    super.key,
    required this.label,
    this.hint,
    this.error,
    this.helper,
    this.controller,
    this.onChanged,
    this.minLines = 4,
    this.clean = false,
  });

  @override
  Widget build(BuildContext context) {
    return DSTextField(
      label: label,
      hint: hint,
      error: error,
      helper: helper,
      controller: controller,
      onChanged: onChanged,
      maxLines: minLines,
      keyboardType: TextInputType.multiline,
      clean: clean,
    );
  }
}
