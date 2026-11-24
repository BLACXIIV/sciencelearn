import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/shadows.dart';
import '../tokens/typography.dart';
import 'icon.dart';

/// CodeInput — row of chunky cells for a short code (class join codes).
/// A transparent TextField on top captures typing + paste; each cell is a
/// mini card (radius 14, line border, blue edge on the active cell).
/// Controlled: pass `value` + `onChanged` like other DS fields.
class DSCodeInput extends StatefulWidget {
  final String? label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? error;
  final int length;
  final bool enabled;

  const DSCodeInput({
    super.key,
    this.label,
    required this.value,
    required this.onChanged,
    this.error,
    this.length = 6,
    this.enabled = true,
  });

  @override
  State<DSCodeInput> createState() => _DSCodeInputState();
}

class _DSCodeInputState extends State<DSCodeInput> {
  late final TextEditingController _c =
      TextEditingController(text: widget.value);
  late final FocusNode _focus = FocusNode()..addListener(_onFocus);

  @override
  void didUpdateWidget(DSCodeInput old) {
    super.didUpdateWidget(old);
    if (widget.value != _c.text) {
      _c.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  void _onFocus() => setState(() {});

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocus)
      ..dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null && widget.error!.isNotEmpty;
    final active = widget.value.length.clamp(0, widget.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: DSText.label),
          const SizedBox(height: 6),
        ],
        SizedBox(
          height: 54,
          child: Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < widget.length; i++)
                    _CodeCell(
                      char: i < widget.value.length ? widget.value[i] : '',
                      active: _focus.hasFocus && i == active,
                      error: hasError,
                      enabled: widget.enabled,
                    ),
                ],
              ),
              Positioned.fill(
                child: TextField(
                  controller: _c,
                  focusNode: _focus,
                  enabled: widget.enabled,
                  maxLength: widget.length,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
                    _UpperCaseFormatter(),
                  ],
                  onChanged: widget.onChanged,
                  style: const TextStyle(color: Colors.transparent),
                  cursorColor: Colors.transparent,
                  showCursor: false,
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const DSIcon(DSIconName.alert, size: 14, color: DSColors.error),
              const SizedBox(width: 6),
              Expanded(child: Text(widget.error!, style: DSText.caption.copyWith(color: DSColors.error))),
            ],
          ),
        ],
      ],
    );
  }
}

class _CodeCell extends StatelessWidget {
  final String char;
  final bool active;
  final bool error;
  final bool enabled;
  const _CodeCell({required this.char, required this.active, required this.error, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: DSColors.surface,
        borderRadius: DSRadii.inputBr,
        border: Border.all(color: error ? DSColors.error : active ? DSColors.blue : DSColors.line),
        boxShadow: dsEdge(error ? DSColors.error : active ? DSColors.edgeBlue : DSColors.edgeCard, h: 4),
      ),
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: Text(
          char.isEmpty ? ' ' : char,
          style: DSText.h3.copyWith(fontSize: 20, color: DSColors.navy),
        ),
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}
