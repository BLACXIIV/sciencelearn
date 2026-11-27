import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import 'card.dart';
import 'icon_button.dart';
import 'icon.dart';
import '../tokens/typography.dart';
import '../tokens/spacing.dart';

/// Shows the DS modal: centered white card (radius 22, 6px card edge), title
/// row with close button, body and right-aligned actions. Returns the result.
Future<T?> showDSModal<T>(
  BuildContext context, {
  required String title,
  Widget? body,
  List<Widget>? actions,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    // Nearest navigator (shell branch), not root — callers close the dialog
    // with Navigator.of(context).pop(), which resolves to the shell nav.
    // On the root nav that pop would remove the screen route instead
    // (white screen) and the action would never run.
    useRootNavigator: false,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black.withValues(alpha: 0.25),
    builder: (context) => DSModal(title: title, body: body, actions: actions),
  );
}

/// The dialog chrome itself (use showDSModal to present it).
class DSModal extends StatelessWidget {
  final String title;
  final Widget? body;
  final List<Widget>? actions;

  const DSModal({super.key, required this.title, this.body, this.actions});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(DSSpacing.s4),
      child: DSCard(
        variant: DSCardVariant.white,
        padding: const EdgeInsets.all(DSSpacing.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: DSText.h3)),
                DSIconButton(
                  icon: DSIconName.close,
                  label: 'Close dialog',
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
            if (body != null) ...[
              const SizedBox(height: DSSpacing.s4),
              DefaultTextStyle.merge(
                style: DSText.bodySm.copyWith(color: DSColors.inkSoft),
                child: body!,
              ),
            ],
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: DSSpacing.s5),
              Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      for (var i = 0; i < actions!.length; i++) ...[
                        if (i > 0) const SizedBox(width: DSSpacing.s3),
                        actions![i],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
