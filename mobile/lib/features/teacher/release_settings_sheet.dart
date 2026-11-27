import 'package:flutter/material.dart';
import '../../data/repository.dart';
import '../../design_system/design_system.dart';

/// Release-settings bottom sheet shared by the builder's header chip and
/// the activity card's "..." menu: "Instant scores" / "Manual release"
/// radios plus "Release scores now" (with confirm) while manual+pending.
/// Mutates immediately like the web dropdown — caller reloads after.
Future<void> showReleaseSettingsSheet(
    BuildContext context, Repo repo, Json a) async {
  final id = '${a['id']}';
  var mode = '${a['release_scores'] ?? 'immediate'}';
  var released = a['scores_released'] == true;
  await showDSBottomSheet<void>(
    context,
    child: StatefulBuilder(builder: (ctx, setS) {
      Widget radio(String value, String label, String sub) => InkWell(
            onTap: () async {
              if (mode == value) return;
              try {
                await repo.setScoreRelease(id, value);
                setS(() => mode = value);
              } catch (e) {
                if (ctx.mounted) {
                  DSToast.show(ctx, message: '$e', tone: DSToastTone.error);
                }
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color:
                            mode == value ? DSColors.blue : DSColors.line,
                        width: 2),
                  ),
                  child: mode == value
                      ? Center(
                          child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: DSColors.blue)))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: DSText.title),
                        Text(sub,
                            style: DSText.caption
                                .copyWith(color: DSColors.muted)),
                      ]),
                ),
              ]),
            ),
          );
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          radio('immediate', 'Instant scores',
              'Students see their score right after submit.'),
          radio('manual', 'Manual release',
              'You release scores when ready.'),
          if (mode == 'manual' && !released) ...[
            const SizedBox(height: 8),
            DSButton(
              fullWidth: true,
              onPressed: () async {
                final ok = await showDSModal<bool>(
                  ctx,
                  title: 'Release scores now?',
                  body: Text(
                    'Students who already took this activity will see their scores right away.',
                    style: DSText.body,
                  ),
                  actions: [
                    DSButton(
                      variant: DSButtonVariant.outline,
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    DSButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Release'),
                    ),
                  ],
                );
                if (ok != true) return;
                try {
                  await repo.releaseScores(id);
                  setS(() => released = true);
                } catch (e) {
                  if (ctx.mounted) {
                    DSToast.show(ctx,
                        message: '$e', tone: DSToastTone.error);
                  }
                }
              },
              child: const Text('Release scores now'),
            ),
          ],
          if (mode == 'manual' && released)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: DSStatusBadge(
                  status: DSStatus.released, label: 'Scores released'),
            ),
        ]),
      );
    }),
  );
}
