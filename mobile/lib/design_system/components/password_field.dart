import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import 'icon.dart';
import 'text_field.dart';

/// PasswordField — DSTextField with a show/hide eye toggle in the field.
/// Toggle hit area is 44px. Pass autofill hints from the caller.
class DSPasswordField extends StatefulWidget {
  final String label;
  final String? hint;
  final String? error;
  final String? helper;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const DSPasswordField({
    super.key,
    required this.label,
    this.hint,
    this.error,
    this.helper,
    this.controller,
    this.onChanged,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  State<DSPasswordField> createState() => _DSPasswordFieldState();
}

class _DSPasswordFieldState extends State<DSPasswordField> {
  bool _show = false;

  @override
  Widget build(BuildContext context) {
    return DSTextField(
      label: widget.label,
      hint: widget.hint,
      error: widget.error,
      helper: widget.helper,
      controller: widget.controller,
      onChanged: widget.onChanged,
      obscureText: !_show,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      trailing: SizedBox(
        width: 44,
        height: 44,
        child: IconButton(
          tooltip: _show ? 'Hide password' : 'Show password',
          onPressed: () => setState(() => _show = !_show),
          icon: DSIcon(_show ? DSIconName.hide : DSIconName.show, size: 18, color: DSColors.muted),
        ),
      ),
    );
  }
}
