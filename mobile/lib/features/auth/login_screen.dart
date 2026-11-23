import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;
  String? _err;

  Future<void> _go({required bool signUp}) async {
    setState(() { _busy = true; _err = null; });
    try {
      final auth = Supabase.instance.client.auth;
      if (signUp) {
        await auth.signUp(email: _email.text.trim(), password: _pass.text, data: {'full_name': _email.text.split('@').first});
      } else {
        await auth.signInWithPassword(email: _email.text.trim(), password: _pass.text);
      }
    } on AuthException catch (e) {
      setState(() => _err = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.navy, AppColors.blue], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.science, size: 56, color: AppColors.blue),
                    Text('ScienceLearn', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const Text('Learn • Explore • Excel'),
                    const SizedBox(height: 20),
                    TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
                    TextField(controller: _pass, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
                    if (_err != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_err!, style: const TextStyle(color: Colors.red))),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _busy ? null : () => _go(signUp: false), child: const Text('Sign in')),
                    TextButton(onPressed: _busy ? null : () => _go(signUp: true), child: const Text('Create student account')),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
}
