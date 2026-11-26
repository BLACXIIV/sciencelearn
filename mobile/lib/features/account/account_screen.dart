import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';
import '../../design_system/design_system.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});
  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  bool _busy = false;

  Future<void> _changePhoto() async {
    const group =
        XTypeGroup(label: 'Images', extensions: ['png', 'jpg', 'jpeg', 'webp']);
    final file = await openFile(acceptedTypeGroups: [group]);
    if (file == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final ext = file.name.split('.').last.toLowerCase();
      final mime = const {
            'png': 'image/png',
            'jpg': 'image/jpeg',
            'jpeg': 'image/jpeg',
            'webp': 'image/webp'
          }[ext] ??
          'image/png';
      final key = await ref
          .read(repoProvider)
          .uploadAvatar(await file.readAsBytes(), file.name, mime);
      await ref.read(repoProvider).setAvatar(key);
      ref.invalidate(meProvider);
      if (mounted) {
        DSToast.show(context,
            message: 'Profile photo updated', tone: DSToastTone.success);
      }
    } catch (e) {
      if (mounted) {
        DSToast.show(context,
            message: 'Upload failed: $e', tone: DSToastTone.error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(meProvider);
    return Scaffold(
      body: Column(children: [
        DSPageHeader(
          compact: true,
          child: SafeArea(
            bottom: false,
            child: Text('Account', style: DSText.h2),
          ),
        ),
        Expanded(
            child: MaxWidth(
                child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            DSCard(
              child: Column(children: [
                const SizedBox(height: 8),
                const UserAvatar(radius: 44),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Image.asset('assets/brand/logo.png', width: 28, height: 28),
                  const SizedBox(width: 8),
                  Flexible(
                      child: Text('ScienceLearn',
                          style: DSText.h2, overflow: TextOverflow.ellipsis)),
                ]),
                Text('Learn • Explore • Excel',
                    style: DSText.bodySm.copyWith(color: DSColors.muted)),
                const SizedBox(height: 4),
                if (me.valueOrNull != null)
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(
                          text: '${me.valueOrNull?['full_name']}',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      TextSpan(text: ' · ${me.valueOrNull?['role']}'),
                    ]),
                    style: DSText.body,
                  ),
                const SizedBox(height: 8),
                DSButton(
                  variant: DSButtonVariant.outline,
                  leadingIcon: DSIconName.camera,
                  loading: _busy,
                  onPressed: _busy ? null : _changePhoto,
                  child: Text(_busy ? 'Uploading…' : 'Change photo'),
                ),
                const SizedBox(height: 8),
              ]),
            ),
            const SizedBox(height: 12),
            const DSCard(
              child: Column(children: [
                _AboutRow(
                    label: 'Developed by',
                    value: 'Regym R. Medina',
                    icon: DSIconName.account),
                DSDivider(),
                _AboutRow(
                    label: 'With the support of',
                    value: 'The Notre Dame of Isulan, Inc.',
                    icon: DSIconName.university),
                DSDivider(),
                _AboutRow(
                    label: 'References',
                    value:
                        'DepEd MATATAG Curriculum, Trusted Scientific Resources',
                    icon: DSIconName.lessons),
              ]),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text('Together for a brighter future',
                  style: DSText.bodySm.copyWith(
                      fontStyle: FontStyle.italic, color: DSColors.muted)),
            ),
            const SizedBox(height: 16),
            DSButton(
              variant: DSButtonVariant.outline,
              leadingIcon: DSIconName.signOut,
              onPressed: () => Supabase.instance.client.auth.signOut(),
              child: const Text('Sign out'),
            ),
          ],
        ))),
      ]),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String label, value;
  final DSIconName icon;
  const _AboutRow(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        DSIcon(icon, size: 20, color: DSColors.blue),
        const SizedBox(width: 10),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: DSText.label),
            Text(value, style: DSText.bodySm),
          ],
        )),
      ]),
    );
  }
}
