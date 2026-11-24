import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/shadows.dart';
import '../tokens/typography.dart';
import 'icon.dart';

enum DSButtonVariant { primary, mint, white, outline, danger, ghost }
enum DSButtonSize { md, sm }

/// Chunky button — the signature SL control: solid fill + solid bottom edge
/// in a darker shade, radius 16. Pressing translates the button down 4px and
/// collapses the edge to 1px (150ms; honors reduced motion via
/// MediaQuery.disableAnimations).
///
/// `primary` = the one main action; `mint`/`white` for navy surfaces;
/// `outline` secondary; `danger` destructive; `ghost` border-only on navy.
class DSButton extends StatefulWidget {
  final DSButtonVariant variant;
  final DSButtonSize size;
  final bool loading;
  final bool disabled;
  final bool fullWidth;
  final DSIconName? leadingIcon;
  final VoidCallback? onPressed;
  final Widget child;

  const DSButton({
    super.key,
    this.variant = DSButtonVariant.primary,
    this.size = DSButtonSize.md,
    this.loading = false,
    this.disabled = false,
    this.fullWidth = false,
    this.leadingIcon,
    this.onPressed,
    required this.child,
  });

  @override
  State<DSButton> createState() => _DSButtonState();
}

class _DSButtonState extends State<DSButton> {
  bool _pressed = false;
  bool get _inactive => widget.disabled || widget.loading || widget.onPressed == null;

  // Disabled = muted sticker: line fill, edge-card edge, muted label.
  (Color, Color, Color?, Color) _colors() => switch (widget.variant) {
        // (fill, text, border, edge)
        _ when widget.disabled => (DSColors.line, DSColors.muted, null, DSColors.edgeCard),
        DSButtonVariant.primary => (DSColors.blue, DSColors.surface, null, DSColors.edgeBlue),
        DSButtonVariant.mint => (DSColors.mint, DSColors.navy, null, DSColors.edgeMint),
        DSButtonVariant.white => (DSColors.surface, DSColors.navy, null, DSColors.edgeWhite),
        DSButtonVariant.outline => (DSColors.surface, DSColors.blue, DSColors.line, DSColors.edgeCard),
        DSButtonVariant.danger => (DSColors.errorSurface, DSColors.error, null, DSColors.error),
        DSButtonVariant.ghost => (Colors.transparent, DSColors.surface, DSColors.surface, Colors.transparent),
      };

  void _set(bool v) {
    if (_inactive || v == _pressed) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final (fill, text, border, edge) = _colors();
    final isSm = widget.size == DSButtonSize.sm;
    final h = widget.variant == DSButtonVariant.outline ? 4 : 5;

    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: _inactive ? null : widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _pressed ? 4 : 0, 0),
        width: widget.fullWidth ? double.infinity : null,
        constraints: BoxConstraints(minHeight: isSm ? 44 : 52),
        padding: EdgeInsets.symmetric(horizontal: isSm ? 20 : 26, vertical: isSm ? 10 : 14),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: DSRadii.buttonBr,
          border: border != null ? Border.all(color: border, width: widget.variant == DSButtonVariant.ghost ? 2 : 1) : null,
          boxShadow: widget.variant == DSButtonVariant.ghost
              ? const []
              : dsEdge(edge, h: _pressed ? 1 : h),
        ),
        child: Row(
          mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.loading)
              SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: text),
              )
            else ...[
              if (widget.leadingIcon != null) ...[
                DSIcon(widget.leadingIcon!, size: isSm ? 16 : 18, color: text),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: DefaultTextStyle.merge(
                  style: DSText.button.copyWith(color: text),
                  child: widget.child,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
