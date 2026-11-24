import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repository.dart';
import '../design_system/design_system.dart';
import 'icons.dart';
import 'theme.dart';
import 'tokens.dart';

/// Current user's avatar: R2 photo when set, initials tile otherwise.
class UserAvatar extends ConsumerWidget {
  final double radius;
  const UserAvatar({super.key, this.radius = 28});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider).valueOrNull;
    final key = me?['avatar_url'] as String?;
    final name = (me?['full_name'] as String?)?.trim();
    final repo = ref.read(repoProvider);
    Widget avatar(String? url) => DSAvatar(
          name: (name == null || name.isEmpty) ? 'Me' : name,
          imageUrl: url,
          size: radius * 2,
        );
    if (key == null || key.isEmpty) return avatar(null);
    return FutureBuilder<String?>(
      future: repo.signedUrl(key),
      builder: (_, s) => avatar(s.data),
    );
  }
}

/// Chunky white card â€” the SL card treatment (matches web `.card`).
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
