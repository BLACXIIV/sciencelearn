import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  bool _obscure = true;
  String? _err;

  Future<void> _signIn() async {
    setState(() { _busy = true; _err = null; });
    try {
      await Supabase.instance.client.auth
          .signInWithPassword(email: _email.text.trim(), password: _pass.text);
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
                    Icon(Icons.science, size: 56, color: Theme.of(context).colorScheme.primary),
                    Text('ScienceLearn', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const Text('Learn • Explore • Excel'),
                    const SizedBox(height: 20),
                    AutofillGroup(child: Column(children: [
                      TextField(
                        controller: _email,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _pass,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            tooltip: _obscure ? 'Show password' : 'Hide password',
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        obscureText: _obscure,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _busy ? null : _signIn(),
                      ),
                    ])),
                    if (_err != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_err!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _busy ? null : _signIn, child: const Text('Sign in')),
                    TextButton(onPressed: _busy ? null : () => context.push('/signup'), child: const Text('Create an account')),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
}
