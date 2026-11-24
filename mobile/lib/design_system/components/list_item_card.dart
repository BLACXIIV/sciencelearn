import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';
import 'card.dart';

/// ListItemCard — the standard tappable list row: white card with leading
/// media, title + subtitle, and a trailing slot. Pass [onTap] for
/// interactive rows; [pending]/[disabled] mute it. Replaces hand-rolled
/// icon+text+chevron rows.
class DSListItemCard extends StatelessWidget {
  /// Leading slot — DSThumbnail, DSIcon or DSAvatar.
  final Widget? leading;
  final Widget title;

  /// Secondary line under the title — text or a small element
  /// (e.g. a DSProgressBar row in a Column).
  final Widget? subtitle;

  /// Trailing slot — DSBadge, score, chevron.
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Awaiting state (e.g. pending class join): non-interactive, dimmed leading.
  final bool pending;
  final bool disabled;

  const DSListItemCard({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.pending = false,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final interactive = !pending && !disabled && onTap != null;
    final lead = leading == null
        ? null
        : Opacity(opacity: pending || disabled ? 0.55 : 1, child: leading);

    final row = DSCard(
      padding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.s4, vertical: DSSpacing.s3),
      child: Row(children: [
        if (lead != null) ...[lead, const SizedBox(width: DSSpacing.s3)],
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            DefaultTextStyle.merge(
              style: DSText.title.copyWith(color: DSColors.ink),
              child: title,
            ),
            if (subtitle != null)
              DefaultTextStyle.merge(
                style: DSText.caption.copyWith(color: DSColors.muted),
                child: subtitle!,
              ),
          ]),
        ),
        if (trailing != null) ...[const SizedBox(width: DSSpacing.s2), trailing!],
      ]),
    );

    if (!interactive) return row;
    return GestureDetector(onTap: onTap, child: row);
  }
}
