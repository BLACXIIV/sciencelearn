import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/icons.dart';
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

  /// Accepts a real email or a bare username ("test2" -> test2@sciencelearn.local).
  String get _loginId {
    final id = _email.text.trim();
    return id.contains('@') ? id : '$id@sciencelearn.local';
  }

  Future<void> _signIn() async {
    setState(() { _busy = true; _err = null; });
    try {
      await Supabase.instance.client.auth
          .signInWithPassword(email: _loginId, password: _pass.text);
    } on AuthException catch (e) {
      setState(() => _err = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.bg, AppColors.surface2], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          ),
          child: Stack(children: [
            Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const EmojiIcon(AppEmoji.science, size: 72),
                    Text('ScienceLearn', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const Text('Learn • Explore • Excel'),
                    const SizedBox(height: 20),
                    AutofillGroup(child: Column(children: [
                      TextField(
                        controller: _email,
                        decoration: const InputDecoration(labelText: 'Email or username'),
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
                            icon: Icon(_obscure ? AppIcons.show : AppIcons.hide),
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
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 12, top: 8),
                child: IconButton(
                  icon: const Icon(AppIcons.back),
                  tooltip: 'Back',
                  onPressed: () => context.canPop() ? context.pop() : context.go('/welcome'),
                ),
              ),
            ),
          ]),
        ),
      );
}
