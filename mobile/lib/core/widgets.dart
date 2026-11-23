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
        color: color ?? Theme.of(context).colorScheme.surface,
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
  const Bar(this.value, {super.key, this.color = AppColors.success});
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: value.clamp(0, 1),
          minHeight: 8,
          color: color,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.cloud_off_outlined, size: 40, color: scheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text("Couldn't load this right now", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Check your connection and try again.',
              style: TextStyle(color: scheme.onSurfaceVariant), textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            FilledButton.tonalIcon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Try Again')),
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
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 40, color: scheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: 4),
            Text(message!, style: TextStyle(color: scheme.onSurfaceVariant), textAlign: TextAlign.center),
          ],
        ]),
      ),
    );
  }
}
