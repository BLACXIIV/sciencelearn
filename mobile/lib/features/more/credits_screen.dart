import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Credits')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const Icon(Icons.science, size: 64, color: AppColors.blue),
          const Center(child: Text('ScienceLearn', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800))),
          const Center(child: Text('Learn • Explore • Excel')),
          const SizedBox(height: 20),
          const AppCard(child: ListTile(leading: Icon(Icons.person), title: Text('Developed by'), subtitle: Text('Regym R. Medina'))),
          const SizedBox(height: 8),
          const AppCard(child: ListTile(leading: Icon(Icons.account_balance), title: Text('With the support of'), subtitle: Text('The Notre Dame of Isulan, Inc.'))),
          const SizedBox(height: 8),
          const AppCard(child: ListTile(leading: Icon(Icons.menu_book), title: Text('References'), subtitle: Text('DepEd MATATAG Curriculum, Trusted Scientific Resources'))),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
            onPressed: () => Supabase.instance.client.auth.signOut(),
          ),
        ]),
      );
}
