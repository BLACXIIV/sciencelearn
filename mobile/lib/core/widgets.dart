import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repository.dart';
import 'icons.dart';
import 'theme.dart';

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
                        width: radius * 2, height: radius * 2, fit: BoxFit.cover,
                        placeholder: (_, __) => Icon(AppIcons.account, size: radius, color: AppColors.muted),
                        errorWidget: (_, __, ___) => Icon(AppIcons.account, size: radius, color: AppColors.muted),
                      ),
                    ),
            ),
    );
  }
}

/// Card chrome for the selected surface style. `base` is the card's solid
/// color; styles reshape how it renders (translucent, shadowed, gradient).
BoxDecoration surfaceDecoration(SurfaceStyle style, Color base,
    {double radius = 16}) {
  final dark = AppColors.palette == darkPalette;
  switch (style) {
    case SurfaceStyle.flat:
      return BoxDecoration(color: base, borderRadius: BorderRadius.circular(radius));
    case SurfaceStyle.glass:
      return BoxDecoration(
        color: base.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.text.withValues(alpha: 0.12)),
      );
    case SurfaceStyle.neo:
      return BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: dark
            ? const [
                BoxShadow(color: Colors.black54, blurRadius: 14, offset: Offset(6, 6)),
                BoxShadow(color: Color(0x0DFFFFFF), blurRadius: 10, offset: Offset(-4, -4)),
              ]
            : const [
                BoxShadow(color: Color(0x738C98AF), blurRadius: 16, offset: Offset(6, 6)),
                BoxShadow(color: Colors.white, blurRadius: 12, offset: Offset(-4, -4)),
              ],
      );
    case SurfaceStyle.skeuo:
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.alphaBlend(AppColors.text.withValues(alpha: dark ? 0.07 : 0.04), base),
            base,
          ],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.line),
        boxShadow: dark
            ? const [BoxShadow(color: Colors.black45, blurRadius: 18, offset: Offset(0, 8))]
            : const [BoxShadow(color: Color(0x4D5A6882), blurRadius: 14, offset: Offset(0, 6))],
      );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.onTap, this.color});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: surfaceDecoration(AppColors.surfaceStyle, color ?? AppColors.surface),
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
  const Bar(this.value, {super.key, this.color = AppColors.success});
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: value.clamp(0, 1),
          minHeight: 8,
          color: color,
          backgroundColor: AppColors.surface2,
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
  const RingChart(this.value, {super.key, required this.color, this.size = 64, this.stroke = 6, this.label});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size, height: size,
        child: CustomPaint(
          painter: _RingPainter(value.clamp(0, 1), color, stroke),
          child: Center(
            child: Text(label ?? '${(value * 100).round()}%',
                style: TextStyle(fontSize: size * 0.22, fontWeight: FontWeight.w700)),
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
    canvas.drawArc(rect, 0, math.pi * 2, false,
        Paint()..color = AppColors.surface2..style = PaintingStyle.stroke..strokeWidth = stroke..strokeCap = StrokeCap.round);
    if (value > 0) {
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false,
          Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = stroke..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => value != old.value || color != old.color;
}

/// One row in a "breakdown" list: colored dot, percent, name, trailing value.
class BreakdownRow extends StatelessWidget {
  final Color color;
  final String percent;
  final String label;
  final String value;
  const BreakdownRow({super.key, required this.color, required this.percent, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 10),
          SizedBox(width: 48, child: Text(percent, style: const TextStyle(fontWeight: FontWeight.w700))),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
      );
}

/// Floating island bottom nav: a rounded bar hovering over the page edge,
/// icon + label items, active item tinted with the accent color.
class IslandNavBar extends StatelessWidget {
  final int currentIndex;
  final List<({IconData icon, String label})> items;
  final ValueChanged<int> onSelect;
  const IslandNavBar({super.key, required this.currentIndex, required this.items, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      // Row + Flexible(loose): centers the bar and caps it at ~560 without
      // expanding vertically (Align/Center fill the unbounded nav slot) or
      // overflowing narrow screens (a bare ConstrainedBox child could).
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            fit: FlexFit.loose,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.line),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 24, offset: Offset(0, 8))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelect(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(items[i].icon, size: 22,
                          color: i == currentIndex ? AppColors.blue : AppColors.muted),
                      const SizedBox(height: 3),
                      Text(items[i].label,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: i == currentIndex ? FontWeight.w600 : FontWeight.w400,
                              color: i == currentIndex ? AppColors.blue : AppColors.muted)),
                    ]),
                  ),
                ),
              ),
          ],
        ),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
  const AsyncView({super.key, required this.snap, required this.builder, this.onRetry});
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
          Text("Couldn't load this right now", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Check your connection and try again.',
              style: TextStyle(color: AppColors.muted), textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            FilledButton.tonalIcon(onPressed: onRetry, icon: const Icon(AppIcons.retry), label: const Text('Try Again')),
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
  const EmptyState({super.key, required this.icon, required this.title, this.message});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 40, color: AppColors.muted),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: 4),
            Text(message!, style: TextStyle(color: AppColors.muted), textAlign: TextAlign.center),
          ],
        ]),
      ),
    );
  }
}
