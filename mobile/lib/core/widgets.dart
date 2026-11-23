import 'package:flutter/material.dart';
import 'theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.onTap, this.color});

  @override
  Widget build(BuildContext context) => Material(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 1.5,
        shadowColor: Colors.black12,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      );
}

class Bar extends StatelessWidget {
  final double value; // 0..1
  final Color color;
  const Bar(this.value, {super.key, this.color = AppColors.green});
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: value.clamp(0, 1), minHeight: 8, color: color, backgroundColor: const Color(0xFFE2E8F0)),
      );
}

class AsyncView<T> extends StatelessWidget {
  final AsyncSnapshot<T> snap;
  final Widget Function(T data) builder;
  const AsyncView({super.key, required this.snap, required this.builder});
  @override
  Widget build(BuildContext context) {
    if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
    return builder(snap.data as T);
  }
}
