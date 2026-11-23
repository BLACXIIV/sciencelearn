import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';

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
      body: ListView(padding: const EdgeInsets.all(20), children: [
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
        const EmojiIcon(AppEmoji.science, size: 52),
        const Center(child: Text('ScienceLearn', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800))),
        const Center(child: Text('Learn • Explore • Excel', style: TextStyle(color: AppColors.muted))),
        const SizedBox(height: 20),
        const AppCard(child: ListTile(leading: Icon(AppIcons.account), title: Text('Developed by'), subtitle: Text('Regym R. Medina'))),
        const SizedBox(height: 8),
        const AppCard(child: ListTile(leading: Icon(AppIcons.university), title: Text('With the support of'), subtitle: Text('The Notre Dame of Isulan, Inc.'))),
        const SizedBox(height: 8),
        const AppCard(child: ListTile(leading: Icon(AppIcons.lessons), title: Text('References'), subtitle: Text('DepEd MATATAG Curriculum, Trusted Scientific Resources'))),
        const SizedBox(height: 20),
        const Center(
          child: Text('Together for a Brighter Future',
              style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.muted)),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          icon: const Icon(AppIcons.signOut),
          label: const Text('Sign out'),
          onPressed: () => Supabase.instance.client.auth.signOut(),
        ),
      ]),
    );
  }
}
