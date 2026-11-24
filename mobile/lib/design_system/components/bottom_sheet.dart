import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Shows the DS bottom sheet: white, top corners rounded 32px, decorative
/// drag handle, dim barrier, content-driven height that grows with the
/// keyboard. Returns the sheet's result.
Future<T?> showDSBottomSheet<T>(
  BuildContext context, {
  required Widget child,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: isDismissible,
    barrierColor: Colors.black.withValues(alpha: 0.25),
    backgroundColor: Colors.transparent,
    transitionAnimationController: null,
    builder: (context) => DSBottomSheet(child: child),
  );
}

/// The sheet chrome itself — embeds inside showModalBottomSheet builders.
/// Top radius 32, decorative 40×5 handle, viewInsets-aware body padding.
class DSBottomSheet extends StatelessWidget {
  final Widget child;
  const DSBottomSheet({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: DSColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(DSRadii.panel)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                DSSpacing.s5, 12, DSSpacing.s5, DSSpacing.s5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: DSColors.track,
                    borderRadius: DSRadii.pillBr,
                  ),
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
