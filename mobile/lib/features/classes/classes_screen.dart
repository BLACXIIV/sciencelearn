import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';
import '../../design_system/design_system.dart';

final enrolledClassesProvider = FutureProvider.autoDispose((ref) {
  ref.watch(authChangesProvider);
  return ref.read(repoProvider).enrolledClasses();
});

/// Student class list: join by code + enrolled classes with status badges.
class MyClassesScreen extends ConsumerStatefulWidget {
  const MyClassesScreen({super.key});
  @override
  ConsumerState<MyClassesScreen> createState() => _MyClassesState();
}

class _MyClassesState extends ConsumerState<MyClassesScreen> {
  String _code = '';
  bool _busy = false;
  String? _msg;
  bool _err = false;

  Future<void> _join() async {
    setState(() {
      _busy = true;
      _msg = null;
    });
    try {
      final r = await ref.read(repoProvider).joinClass(_code.trim());
      _code = '';
      _err = false;
      _msg = r['status'] == 'pending'
          ? 'Request sent to ${r['name']}, waiting for teacher approval'
          : 'Joined ${r['name']}';
      ref.invalidate(enrolledClassesProvider);
    } catch (e) {
      _msg = '$e'.replaceFirst('Exception: ', '');
      _err = true;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final classes = ref.watch(enrolledClassesProvider);
    return Scaffold(
      body: MaxWidth(
          child: Column(children: [
        DSPageHeader(
          compact: true,
          child: SafeArea(
            bottom: false,
            child: Text('My classes', style: DSText.h2),
          ),
        ),
        Expanded(
            child: ListView(padding: const EdgeInsets.all(16), children: [
          DSCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                Text('Join a class', style: DSText.title),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                      child: DSCodeInput(
                    value: _code,
                    onChanged: (v) => setState(() => _code = v),
                    enabled: !_busy,
                  )),
                  const SizedBox(width: 8),
                  DSButton(
                    loading: _busy,
                    disabled: _busy || _code.trim().isEmpty,
                    onPressed: _join,
                    child: const Text('Join'),
                  ),
                ]),
                if (_msg != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_msg!,
                        style: DSText.caption.copyWith(
                            color: _err ? DSColors.error : DSColors.success)),
                  ),
              ])),
          const SizedBox(height: 16),
          classes.when(
            loading: () => const Center(child: DSLoadingIndicator()),
            error: (e, _) => DSEmptyState(
              icon: DSIconName.offline,
              title: "Couldn't load this right now",
              body: 'Check your connection and try again.',
              action: DSButton(
                variant: DSButtonVariant.outline,
                size: DSButtonSize.sm,
                leadingIcon: DSIconName.retry,
                onPressed: () => ref.invalidate(enrolledClassesProvider),
                child: const Text('Try again'),
              ),
            ),
            data: (rows) {
              if (rows.isEmpty) {
                return const DSCard(
                    child: DSEmptyState(
                        icon: DSIconName.students,
                        title: 'No classes yet',
                        body: 'Get a class code from your teacher.'));
              }
              return Column(children: [
                for (final e in rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: e['status'] == 'active'
                        ? DSListItemCard(
                            onTap: () => context.push(
                                '/class/${e['class_id']}?name=${Uri.encodeComponent('${e['classes']?['name'] ?? 'Class'}')}'),
                            leading: const DSIcon(DSIconName.school,
                                size: 20, color: DSColors.blue),
                            title: Text('${e['classes']?['name'] ?? 'Class'}'),
                            trailing: const DSIcon(DSIconName.chevron,
                                color: DSColors.muted),
                          )
                        : DSListItemCard(
                            pending: true,
                            leading: const DSIcon(DSIconName.pending,
                                size: 20, color: DSColors.muted),
                            title: Text('${e['classes']?['name'] ?? 'Class'}'),
                            subtitle:
                                const Text('Waiting for teacher approval'),
                            trailing: const DSBadge(
                                tone: DSBadgeTone.sun, child: Text('Pending')),
                          ),
                  ),
              ]);
            },
          ),
        ])),
      ])),
    );
  }
}
