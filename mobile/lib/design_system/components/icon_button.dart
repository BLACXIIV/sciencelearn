import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/shadows.dart';
import 'icon.dart';

/// Compact icon-only control: white tile, line border, 3px card edge,
/// radius 14. Hit target 44px. For toolbars, row actions, close buttons.
class DSIconButton extends StatefulWidget {
  final DSIconName icon;
  final String label; // semanticLabel — required, there is no visible text
  final VoidCallback? onPressed;
  final bool disabled;
  final double size;

  const DSIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.disabled = false,
    this.size = 44,
  });

  @override
  State<DSIconButton> createState() => _DSIconButtonState();
}

class _DSIconButtonState extends State<DSIconButton> {
  bool _pressed = false;
  bool get _inactive => widget.disabled || widget.onPressed == null;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) {
          if (!_inactive) setState(() => _pressed = true);
        },
        onTapUp: (_) {
          if (_pressed) setState(() => _pressed = false);
        },
        onTapCancel: () {
          if (_pressed) setState(() => _pressed = false);
        },
        onTap: _inactive ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.translationValues(0, _pressed ? 3 : 0, 0),
          width: widget.size,
          height: widget.size,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          decoration: BoxDecoration(
            color: DSColors.surface,
            borderRadius: DSRadii.inputBr,
            border: Border.all(color: DSColors.line),
            boxShadow: dsEdge(DSColors.edgeCard, h: _pressed ? 1 : 3),
          ),
          child: Opacity(
            opacity: widget.disabled ? 0.5 : 1,
            child: Center(
                child: DSIcon(widget.icon, size: 20, color: DSColors.ink)),
          ),
        ),
      ),
    );
  }
}
