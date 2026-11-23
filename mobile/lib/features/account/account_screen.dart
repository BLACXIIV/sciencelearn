import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';
import '../../data/settings.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});
  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  bool _busy = false;

  Future<void> _changePhoto() async {
    const group = XTypeGroup(label: 'Images', extensions: ['png', 'jpg', 'jpeg', 'webp']);
    final file = await openFile(acceptedTypeGroups: [group]);
    if (file == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final ext = file.name.split('.').last.toLowerCase();
      final mime = const {'png': 'image/png', 'jpg': 'image/jpeg', 'jpeg': 'image/jpeg', 'webp': 'image/webp'}[ext] ?? 'image/png';
      final key = await ref.read(repoProvider).uploadAvatar(await file.readAsBytes(), file.name, mime);
      await ref.read(repoProvider).setAvatar(key);
      ref.invalidate(meProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(meProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: MaxWidth(child: ListView(padding: const EdgeInsets.all(20), children: [
        const UserAvatar(radius: 44),
        const SizedBox(height: 8),
        Center(child: Text(me.valueOrNull?['full_name'] ?? '',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
        TextButton.icon(
          icon: _busy
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(AppIcons.camera),
          label: const Text('Change photo'),
          onPressed: _busy ? null : _changePhoto,
        ),
        const SizedBox(height: 8),
        const _AppearanceCard(),
        const SizedBox(height: 16),
        const EmojiIcon(AppEmoji.science, size: 52),
        const Center(child: Text('ScienceLearn', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800))),
        Center(child: Text('Learn • Explore • Excel', style: TextStyle(color: AppColors.muted))),
        const SizedBox(height: 20),
        const AppCard(child: ListTile(leading: Icon(AppIcons.account), title: Text('Developed by'), subtitle: Text('Regym R. Medina'))),
        const SizedBox(height: 8),
        const AppCard(child: ListTile(leading: Icon(AppIcons.university), title: Text('With the support of'), subtitle: Text('The Notre Dame of Isulan, Inc.'))),
        const SizedBox(height: 8),
        const AppCard(child: ListTile(leading: Icon(AppIcons.lessons), title: Text('References'), subtitle: Text('DepEd MATATAG Curriculum, Trusted Scientific Resources'))),
        const SizedBox(height: 20),
        Center(
          child: Text('Together for a Brighter Future',
              style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.muted)),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          icon: const Icon(AppIcons.signOut),
          label: const Text('Sign out'),
          onPressed: () => Supabase.instance.client.auth.signOut(),
        ),
      ])),
    );
  }
}

/// Theme controls: mode (system/dark/light), accent color, surface style.
class _AppearanceCard extends ConsumerWidget {
  const _AppearanceCard();

  static const _surfaces = {
    SurfaceStyle.flat: 'Flat',
    SurfaceStyle.glass: 'Glass',
    SurfaceStyle.neo: 'Neo',
    SurfaceStyle.skeuo: 'Skeuo',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ap = ref.watch(appearanceProvider);
    final notifier = ref.read(appearanceProvider.notifier);
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(AppIcons.settings, size: 18, color: AppColors.muted),
          const SizedBox(width: 8),
          const Text('Appearance', style: TextStyle(fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 12),
        Text('Mode', style: TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 6),
        SegmentedButton<AppMode>(
          segments: const [
            ButtonSegment(value: AppMode.system, label: Text('System')),
            ButtonSegment(value: AppMode.dark, label: Text('Dark')),
            ButtonSegment(value: AppMode.light, label: Text('Light')),
          ],
          selected: {ap.mode},
          onSelectionChanged: (s) => notifier.setMode(s.first),
          showSelectedIcon: false,
        ),
        const SizedBox(height: 14),
        Text('Accent color', style: TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 8),
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final a in kAccents)
            GestureDetector(
              onTap: () => notifier.setAccent(a.id),
              child: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: a.hex,
                  shape: BoxShape.circle,
                  border: Border.all(
                    width: 2.5,
                    color: ap.accentId == a.id ? AppColors.text : Colors.transparent,
                  ),
                ),
                child: ap.accentId == a.id
                    ? Icon(AppIcons.done, size: 16, color: a.on)
                    : null,
              ),
            ),
        ]),
        const SizedBox(height: 14),
        Text('Panel style', style: TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final e in _surfaces.entries)
            ChoiceChip(
              label: Text(e.value),
              selected: ap.surface == e.key,
              onSelected: (_) => notifier.setSurface(e.key),
            ),
        ]),
      ]),
    );
  }
}
