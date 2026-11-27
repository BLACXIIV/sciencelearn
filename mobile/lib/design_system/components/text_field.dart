import 'package:flutter/material.dart';

import '../../core/text_clean.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/typography.dart';
import 'icon.dart';

/// Labeled text input: Lexend label above, 50px-tall field, radius 14,
/// line border → 2px blue on focus. `error` swaps the border to coral and
/// shows an icon + message under the field; `helper` is the muted variant.
/// Base chrome shared by DSPasswordField / DSSearchField / DSTextArea.
class DSTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? error;
  final String? helper;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? leading;
  final Widget? trailing;
  /// `minLines: 1, maxLines: null` makes the field grow to fit its text.
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  /// Normalize pasted/typed text live (docx symbol glyphs, arrows, subscripts).
  final bool clean;

  const DSTextField({
    super.key,
    required this.label,
    this.hint,
    this.error,
    this.helper,
    this.controller,
    this.onChanged,
    this.keyboardType,
    this.obscureText = false,
    this.leading,
    this.trailing,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.clean = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = error != null && error!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: DSText.label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          obscureText: obscureText,
          minLines: minLines,
          maxLines: maxLines,
          enabled: enabled,
          focusNode: focusNode,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          autofillHints: autofillHints,
          textCapitalization: textCapitalization,
          inputFormatters: clean ? const [CleanTextFormatter()] : null,
          style:
              DSText.bodySm.copyWith(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            // triggers the themed errorBorder; the icon+message row renders below
            error: hasError ? const SizedBox.shrink() : null,
            prefixIcon: leading,
            suffixIcon: trailing,
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child:
                    DSIcon(DSIconName.alert, size: 14, color: DSColors.error),
              ),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(error!,
                      style: DSText.caption.copyWith(color: DSColors.error))),
            ],
          ),
        ] else if (helper != null) ...[
          const SizedBox(height: 6),
          Text(helper!, style: DSText.caption.copyWith(color: DSColors.muted)),
        ],
      ],
    );
  }
}

/// Input border helpers used by the themed fields — radius 14, line border.
OutlineInputBorder dsInputBorder([Color? color, double width = 1]) =>
    OutlineInputBorder(
      borderRadius: DSRadii.inputBr,
      borderSide: BorderSide(color: color ?? DSColors.line, width: width),
    );
