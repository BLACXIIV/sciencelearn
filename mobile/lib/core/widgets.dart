import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../data/repository.dart';
import 'icons.dart';
import 'theme.dart';
import 'tokens.dart';

/// Current user's avatar: R2 photo when set, person icon otherwise.
class UserAvatar extends ConsumerWidget {
  final double radius;
  const UserAvatar({super.key, this.radius = 28});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider).valueOrNull;
    final key = me?['avatar_url'] as String?;
    final repo = ref.read(repoProvider);
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.surface2,
      child: key == null || key.isEmpty
          ? Icon(AppIcons.account, size: radius, color: AppColors.muted)
          : FutureBuilder<String?>(
              future: repo.signedUrl(key),
              builder: (_, s) => s.data == null
                  ? Icon(AppIcons.account, size: radius, color: AppColors.muted)
                  : ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: s.data!,
                        width: radius * 2,
                        height: radius * 2,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Icon(AppIcons.account,
                            size: radius, color: AppColors.muted),
                        errorWidget: (_, __, ___) => Icon(AppIcons.account,
                            size: radius, color: AppColors.muted),
                      ),
                    ),
            ),
    );
  }
}

/// Chunky white card — the SL card treatment (matches web `.card`).
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;
  const AppCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(14),
      this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: color ?? Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SLColors.line),
            boxShadow: chunkyShadow(SLColors.cardShadow, h: 5),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      );
}

class Bar extends StatelessWidget {
  final double value; // 0..1
  final Color color;
  const Bar(this.value, {super.key, this.color = SLColors.blue});
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: value.clamp(0, 1),
          minHeight: 8,
          color: color,
          backgroundColor: SLColors.track,
        ),
      );
}

/// Circular progress ring in the reference style: a colored arc on a dark
/// track with the percentage centered inside.
class RingChart extends StatelessWidget {
  final double value; // 0..1
  final Color color;
  final double size;
  final double stroke;
  final String? label;
  const RingChart(this.value,
      {super.key,
      required this.color,
      this.size = 64,
      this.stroke = 6,
      this.label});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(value.clamp(0, 1), color, stroke),
          child: Center(
            child: Text(label ?? '${(value * 100).round()}%',
                style: TextStyle(
                    fontSize: size * 0.22, fontWeight: FontWeight.w700)),
          ),
        ),
      );
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color color;
  final double stroke;
  _RingPainter(this.value, this.color, this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawArc(
        rect,
        0,
        math.pi * 2,
        false,
        Paint()
          ..color = SLColors.track
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round);
    if (value > 0) {
      canvas.drawArc(
          rect,
          -math.pi / 2,
          math.pi * 2 * value,
          false,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      value != old.value || color != old.color;
}

/// One row in a "breakdown" list: colored dot, percent, name, trailing value.
class BreakdownRow extends StatelessWidget {
  final Color color;
  final String percent;
  final String label;
  final String value;
  const BreakdownRow(
      {super.key,
      required this.color,
      required this.percent,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 10),
          SizedBox(
              width: 48,
              child: Text(percent,
                  style: const TextStyle(fontWeight: FontWeight.w700))),
          const SizedBox(width: 10),
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
      );
}

/// Caps content width and centers it when the window is wider than a phone
/// (tablet, desktop window). Transparent pass-through on narrow screens.
class MaxWidth extends StatelessWidget {
  final Widget child;
  final double max;
  const MaxWidth({super.key, required this.child, this.max = 640});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: max),
          child: child,
        ),
      );
}

class AsyncView<T> extends StatelessWidget {
  final AsyncSnapshot<T> snap;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;
  const AsyncView(
      {super.key, required this.snap, required this.builder, this.onRetry});
  @override
  Widget build(BuildContext context) {
    if (snap.hasError) return ErrorState(onRetry: onRetry);
    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
    return builder(snap.data as T);
  }
}

class ErrorState extends StatelessWidget {
  final VoidCallback? onRetry;
  const ErrorState({super.key, this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(AppIcons.offline, size: 40, color: AppColors.muted),
          const SizedBox(height: 8),
          Text("Couldn't load this right now",
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Check your connection and try again.',
              style: TextStyle(color: AppColors.muted),
              textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(AppIcons.retry),
                label: const Text('Try Again')),
          ],
        ]),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  const EmptyState(
      {super.key, required this.icon, required this.title, this.message});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 40, color: AppColors.muted),
          const SizedBox(height: 8),
          Text(title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: 4),
            Text(message!,
                style: TextStyle(color: AppColors.muted),
                textAlign: TextAlign.center),
          ],
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Design-system widgets (docs/UI_STYLE_GUIDE.md §2) — SL tokens only, no
// dependence on AppColors/appearance prefs. Used by the redesigned screens.
// ---------------------------------------------------------------------------

enum ChunkyVariant { blue, mint, white }

/// Chunky button: solid fill + solid bottom shadow in a darker shade of the
/// fill. Presses translate down 4px while the shadow collapses.
class ChunkyButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final ChunkyVariant variant;
  final EdgeInsets padding;
  final double fontSize;
  final bool busy;
  const ChunkyButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ChunkyVariant.blue,
    this.padding = const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
    this.fontSize = 15,
    this.busy = false,
  });

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, sh) = switch (widget.variant) {
      ChunkyVariant.blue => (SLColors.blue, Colors.white, SLColors.shadowBlue),
      ChunkyVariant.mint => (
          SLColors.mint,
          SLColors.navy,
          SLColors.correctShadow
        ),
      ChunkyVariant.white => (
          Colors.white,
          SLColors.navy,
          SLColors.shadowWhite
        ),
    };
    final noMotion = MediaQuery.disableAnimationsOf(context);
    final enabled = widget.onPressed != null && !widget.busy;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _down = false);
              widget.onPressed!();
            }
          : null,
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedContainer(
        duration: noMotion ? Duration.zero : const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        constraints: const BoxConstraints(minHeight: 48),
        padding: widget.padding,
        transform: Matrix4.translationValues(0, _down ? 4 : 0, 0),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(SLRadii.button),
          boxShadow: [BoxShadow(color: sh, offset: Offset(0, _down ? 1 : 5))],
        ),
        child: Center(
          widthFactor: 1,
          heightFactor:
              1, // shrink-wrap — without it Center fills bounded height (bottomNavigationBar)
          child: widget.busy
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
                )
              : Text(
                  widget.label,
                  style: SLText.display(widget.fontSize)
                      .copyWith(fontWeight: FontWeight.w700, color: fg),
                ),
        ),
      ),
    );
  }
}

/// Sticker chip: a small rotated tag with a solid bottom shadow, Lexend 800.
class StickerChip extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  final double rotation; // degrees, spec range -6..+5
  const StickerChip(
    this.text, {
    super.key,
    required this.color,
    this.textColor = SLColors.navy,
    this.rotation = -5,
  });

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: rotation * math.pi / 180,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: SLColors.chipShadow, offset: Offset(0, 4))
            ],
          ),
          child: Text(text,
              softWrap: false,
              style: SLText.display(13).copyWith(color: textColor)),
        ),
      );
}

/// Mission/module card: pastel fill, permanent slight tilt that flattens on
/// press, optional white icon tile and trailing CTA label.
class MissionCard extends StatelessWidget {
  final Color pastel;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final double tilt; // degrees
  final IconData? icon;
  final String? cta;
  const MissionCard({
    super.key,
    required this.pastel,
    required this.title,
    required this.description,
    this.onTap,
    this.tilt = 0,
    this.icon,
    this.cta,
  });

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: tilt * math.pi / 180,
        child: Container(
          constraints: const BoxConstraints(minHeight: 130),
          decoration: BoxDecoration(
            color: pastel,
            borderRadius: BorderRadius.circular(22),
            boxShadow: chunkyShadow(SLColors.cardShadow),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(22),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (icon != null)
                        Container(
                          width: 44,
                          height: 44,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12)),
                          child: Icon(icon, size: 24, color: SLColors.navy),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(title,
                              maxLines: 1, style: SLText.display(18)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(description,
                          style: SLText.body(13)
                              .copyWith(color: SLColors.inkSoft)),
                      if (cta != null) ...[
                        const Spacer(),
                        Text(cta!,
                            style: SLText.display(14)
                                .copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ]),
              ),
            ),
          ),
        ),
      );
}

enum QuizOptionState { idle, selected, correct, wrong }

/// Quiz option row: circular letter badge + answer text, white by default,
/// mint when correct, soft coral when wrong, blue inner outline when selected.
class QuizOption extends StatelessWidget {
  final String letter;
  final String text;
  final QuizOptionState state;
  final VoidCallback? onTap;
  const QuizOption({
    super.key,
    required this.letter,
    required this.text,
    this.state = QuizOptionState.idle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = switch (state) {
      QuizOptionState.correct => SLColors.correct,
      QuizOptionState.wrong => SLColors.wrong,
      _ => Colors.white,
    };
    final fg =
        state == QuizOptionState.wrong ? SLColors.wrongLabel : SLColors.navy;
    final sh = state == QuizOptionState.correct
        ? SLColors.correctShadow
        : SLColors.shadowWhite;
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: state == QuizOptionState.selected
            ? Border.all(color: SLColors.blue, width: 3)
            : null,
        boxShadow: chunkyShadow(sh, h: 5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                    color: SLColors.paper, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(letter, style: SLText.display(14)),
              ),
              const SizedBox(width: 14),
              Expanded(
                  child:
                      Text(text, style: SLText.label(16).copyWith(color: fg))),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Navy panel with a deep-navy solid bottom shadow.
class DarkPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const DarkPanel(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(24)});

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: SLColors.navy,
          borderRadius: BorderRadius.circular(SLRadii.panel),
          boxShadow: chunkyShadow(SLColors.navyDeep),
        ),
        child: child,
      );
}

/// Light paper circle that Storyset cuate illustrations always sit on when
/// placed on navy. The SVG bleeds slightly past the circle edge (105%).
class HeroCircle extends StatelessWidget {
  final String asset;
  const HeroCircle(this.asset, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        decoration:
            const BoxDecoration(color: SLColors.paper, shape: BoxShape.circle),
        child: Center(
          child: FractionallySizedBox(
            widthFactor: 1.05,
            heightFactor: 1.05,
            child: SvgPicture.asset(asset),
          ),
        ),
      );
}

/// 14px pill progress bar: blue for pre-test, teal for post-test.
class ProgressPill extends StatelessWidget {
  final double value; // 0..1
  final Color color;
  final double height;
  const ProgressPill(this.value,
      {super.key, this.color = SLColors.blue, this.height = 14});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: Container(
          height: height,
          color: SLColors.track,
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0, 1),
            child: Container(color: color),
          ),
        ),
      );
}
