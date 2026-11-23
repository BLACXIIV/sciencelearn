import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/icons.dart';
import '../../core/theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  String _role = 'student';
  bool _busy = false;
  bool _obscure = true;
  String? _err;
  bool _sent = false;

  Future<void> _create() async {
    if (_pass.text != _confirm.text) {
      setState(() => _err = "Passwords don't match");
      return;
    }
    setState(() { _busy = true; _err = null; });
    try {
      final auth = Supabase.instance.client.auth;
      // Real email or bare username ("test2" -> test2@sciencelearn.local).
      final id = _email.text.trim();
      await auth.signUp(
        email: id.contains('@') ? id : '$id@sciencelearn.local',
        password: _pass.text,
        data: {'full_name': _name.text.trim(), 'role': _role},
      );
      // Auto-confirm (dev) signs in immediately and the router redirects;
      // otherwise fall back to the check-your-email view.
      if (auth.currentSession == null && mounted) setState(() => _sent = true);
    } on AuthException catch (e) {
      setState(() => _err = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _fieldDeco(String label, {Widget? suffix}) =>
      InputDecoration(labelText: label, suffixIcon: suffix);

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
                    child: _sent ? _checkEmail(context) : _form(context),
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

  Widget _checkEmail(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(AppIcons.mailVerified, size: 48, color: AppColors.blue),
        const SizedBox(height: 8),
        Text('Check your email', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('We sent a confirmation link to ${_email.text.trim()}. Open it to activate your account, then sign in.',
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        TextButton(onPressed: () => context.go('/login'), child: const Text('Back to Sign In')),
      ]);

  Widget _form(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        const EmojiIcon(AppEmoji.science, size: 72),
        Text('ScienceLearn', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const Text('Create your account'),
        const SizedBox(height: 20),
        AutofillGroup(child: Column(children: [
          TextField(
            controller: _name,
            decoration: _fieldDeco('Full name'),
            autofillHints: const [AutofillHints.name],
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _email,
            decoration: _fieldDeco('Email or username'),
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pass,
            decoration: _fieldDeco('Password', suffix: IconButton(
              icon: Icon(_obscure ? AppIcons.show : AppIcons.hide),
              tooltip: _obscure ? 'Show password' : 'Hide password',
              onPressed: () => setState(() => _obscure = !_obscure),
            )),
            obscureText: _obscure,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _confirm,
            decoration: _fieldDeco('Confirm password'),
            obscureText: _obscure,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _busy ? null : _create(),
          ),
        ])),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('I am aâ€¦', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'student', label: Text('Student'), icon: Icon(AppIcons.school)),
              ButtonSegment(value: 'teacher', label: Text('Teacher'), icon: Icon(AppIcons.presentation)),
            ],
            selected: {_role},
            onSelectionChanged: (s) => setState(() => _role = s.first),
          ),
        ),
        if (_err != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_err!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _busy ? null : _create,
            child: _busy
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Create Account'),
          ),
        ),
        TextButton(onPressed: _busy ? null : () => context.pop(), child: const Text('Already have an account? Sign in')),
      ]);
}
