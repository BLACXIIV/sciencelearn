import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/widgets.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Icon(Icons.science, size: 64, color: scheme.primary),
        const Center(child: Text('ScienceLearn', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800))),
        const Center(child: Text('Learn • Explore • Excel')),
        const SizedBox(height: 20),
        const AppCard(child: ListTile(leading: Icon(Icons.person), title: Text('Developed by'), subtitle: Text('Regym R. Medina'))),
        const SizedBox(height: 8),
        const AppCard(child: ListTile(leading: Icon(Icons.account_balance), title: Text('With the support of'), subtitle: Text('The Notre Dame of Isulan, Inc.'))),
        const SizedBox(height: 8),
        const AppCard(child: ListTile(leading: Icon(Icons.menu_book), title: Text('References'), subtitle: Text('DepEd MATATAG Curriculum, Trusted Scientific Resources'))),
        const SizedBox(height: 20),
        Center(
          child: Text('— Together for a Brighter Future —',
              style: TextStyle(fontStyle: FontStyle.italic, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
          onPressed: () => Supabase.instance.client.auth.signOut(),
        ),
      ]),
    );
  }
}
