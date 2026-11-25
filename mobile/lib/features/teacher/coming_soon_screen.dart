import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../design_system/design_system.dart';

/// Placeholder for More-sheet routes with no screen yet (Review Content,
/// Reports). No backend — just a friendly dead end.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: DSIconButton(
          icon: DSIconName.back,
          label: 'Back',
          onPressed: () => context.pop(),
        ),
        title: const Text('Coming soon'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: DSCard(
          child: DSEmptyState(
            icon: DSIconName.tip,
            title: 'Coming soon',
            body:
                'This section is on the way — check back after the next update.',
          ),
        ),
      ),
    );
  }
}
