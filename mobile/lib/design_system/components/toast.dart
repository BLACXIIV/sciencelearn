import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/shadows.dart';
import '../tokens/typography.dart';
import 'icon.dart';
import 'icon_button.dart';

enum DSToastTone { info, success, error }

/// Toast — bottom notification card: white, radius 22, 5px card edge,
/// leading status icon, auto-dismiss via SnackBar. Call `DSToast.show`.
class DSToast extends StatelessWidget {
  final String message;
  final DSToastTone tone;
  final VoidCallback? onClose;

  const DSToast({
    super.key,
    required this.message,
    this.tone = DSToastTone.info,
    this.onClose,
  });

  /// Shows the toast above the bottom nav. One at a time — a new call
  /// replaces the current one.
  static void show(
    BuildContext context, {
    required String message,
    DSToastTone tone = DSToastTone.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        content: DSToast(
          message: message,
          tone: tone,
          onClose: messenger.hideCurrentSnackBar,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (tone) {
      DSToastTone.info => (DSIconName.info, DSColors.blue),
      DSToastTone.success => (DSIconName.done, DSColors.success),
      DSToastTone.error => (DSIconName.alert, DSColors.error),
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
      decoration: BoxDecoration(
        color: DSColors.surface,
        borderRadius: DSRadii.cardBr,
        border: Border.all(color: DSColors.line),
        boxShadow: dsEdge(DSColors.edgeCard, h: 5),
      ),
      child: Row(
        children: [
          DSIcon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: DSText.bodySm.copyWith(color: DSColors.ink, fontWeight: FontWeight.w500),
            ),
          ),
          DSIconButton(icon: DSIconName.close, label: 'Dismiss', onPressed: onClose),
        ],
      ),
    );
  }
}
