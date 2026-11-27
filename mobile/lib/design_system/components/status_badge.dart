import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/typography.dart';
import 'icon.dart';

enum DSStatusTone { success, warning, danger, neutral }

/// Domain statuses — one meaning, one look (tone + icon are automatic).
enum DSStatus {
  active,
  published,
  released,
  pending,
  manual,
  failed,
  declined,
  offline,
  draft,
  hidden,
}

/// StatusBadge — quiet 12%-tint status pill (22px, pill radius, 12px text,
/// one icon per status). For state ("published", "pending") — not counts
/// (use [DSBadge]) or tags (use [DSChip]).
class DSStatusBadge extends StatelessWidget {
  /// Semantic status — resolves tone + icon from the shared vocabulary.
  final DSStatus? status;

  /// Escape hatch for one-off states not in the vocabulary.
  final DSStatusTone? tone;
  final DSIconName? icon;

  /// Defaults to the status's canonical label.
  final String? label;

  const DSStatusBadge({
    super.key,
    this.status,
    this.tone,
    this.icon,
    this.label,
  });

  static const _map = <DSStatus, (DSStatusTone, DSIconName, String)>{
    DSStatus.active: (DSStatusTone.success, DSIconName.check, 'Active'),
    DSStatus.published: (DSStatusTone.success, DSIconName.check, 'Published'),
    DSStatus.released: (DSStatusTone.success, DSIconName.check, 'Released'),
    DSStatus.pending: (DSStatusTone.warning, DSIconName.pending, 'Pending'),
    DSStatus.manual: (DSStatusTone.warning, DSIconName.pending, 'Manual'),
    DSStatus.failed: (DSStatusTone.danger, DSIconName.close, 'Failed'),
    DSStatus.declined: (DSStatusTone.danger, DSIconName.close, 'Declined'),
    DSStatus.offline: (DSStatusTone.danger, DSIconName.offline, 'Offline'),
    DSStatus.draft: (DSStatusTone.neutral, DSIconName.hide, 'Draft'),
    DSStatus.hidden: (DSStatusTone.neutral, DSIconName.hide, 'Hidden'),
  };

  @override
  Widget build(BuildContext context) {
    final mapped = status != null ? _map[status!] : null;
    final t = mapped?.$1 ?? tone ?? DSStatusTone.neutral;
    final ic = icon ?? mapped?.$2;
    final text = label ?? mapped?.$3 ?? status?.name ?? '';

    final (tint, ink) = switch (t) {
      DSStatusTone.success => (
          DSColors.success.withValues(alpha: .12),
          DSColors.successInk
        ),
      DSStatusTone.warning => (
          DSColors.warning.withValues(alpha: .12),
          DSColors.warningInk
        ),
      DSStatusTone.danger => (
          DSColors.error.withValues(alpha: .12),
          DSColors.error
        ),
      DSStatusTone.neutral => (
          DSColors.muted.withValues(alpha: .12),
          DSColors.neutralInk
        ),
    };

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: tint, borderRadius: DSRadii.pillBr),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ic != null) ...[
            DSIcon(ic, size: 12, color: ink),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: DSText.label
                .copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: ink),
          ),
        ],
      ),
    );
  }
}
