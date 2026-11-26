import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../design_system/design_system.dart';

enum AuthTab { login, signup }

/// Opens the shared auth bottom sheet (Sign in tab by default).
/// Closes by drag-down, barrier tap, or Android back.
Future<void> showAuthSheet(BuildContext context,
        {AuthTab initial = AuthTab.login}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: Colors.black.withValues(alpha: .25),
      backgroundColor: Colors.transparent,
      clipBehavior: Clip.none,
      sheetAnimationStyle: const AnimationStyle(
          duration: Duration(milliseconds: 320), curve: Curves.easeOutCubic),
      builder: (_) => _AuthSheet(initial: initial),
    );

/// White sheet: the Storyset art is the sheet's background — a blurred
/// copy bleeds off the top-right corner behind the handle + switcher.
class _AuthSheet extends StatefulWidget {
  final AuthTab initial;
  const _AuthSheet({required this.initial});

  @override
  State<_AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends State<_AuthSheet> {
  late AuthTab _tab = widget.initial;
  String _signupArt = 'assets/illustrations/student.svg';

  String get _art =>
      _tab == AuthTab.login ? 'assets/illustrations/login.svg' : _signupArt;

  @override
  Widget build(BuildContext context) {
    final noMotion = MediaQuery.disableAnimationsOf(context);
    final dur = noMotion ? Duration.zero : const Duration(milliseconds: 250);
    return GestureDetector(
      // Tapping outside a field dismisses the keyboard.
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: DSColors.surface,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(DSRadii.panel)),
          ),
          // The blurred Storyset art is the sheet's background, bleeding
          // off the top-right corner behind the form.
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(DSRadii.panel)),
            child: Stack(children: [
              Positioned(
                top: -24,
                right: -24,
                child: IgnorePointer(
                  child: AnimatedSwitcher(
                    duration: dur,
                    child: ShaderMask(
                      // Crisp at the corner, fully faded where the title is.
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (r) => const LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          Colors.white,
                          Colors.white,
                          Colors.transparent
                        ],
                        stops: [0.0, 0.42, 0.85],
                      ).createShader(r),
                      child: ImageFiltered(
                        key: ValueKey(_art),
                        imageFilter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                        child: SvgPicture.asset(_art, width: 200),
                      ),
                    ),
                  ),
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                          color: DSColors.track, borderRadius: DSRadii.pillBr),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DSSegmentedControl(
                    options: const [
                      DSSegment('login', 'Log in'),
                      DSSegment('signup', 'Sign up'),
                    ],
                    value: _tab == AuthTab.login ? 'login' : 'signup',
                    onChanged: (v) => setState(() =>
                        _tab = v == 'login' ? AuthTab.login : AuthTab.signup),
                  ),
                  const SizedBox(height: 16),
                  AnimatedSize(
                    duration: dur,
                    curve: Curves.easeInOut,
                    child: AnimatedSwitcher(
                      duration: dur,
                      child: _tab == AuthTab.login
                          ? _LoginForm(
                              key: const ValueKey('login'),
                              onGoSignup: () =>
                                  setState(() => _tab = AuthTab.signup),
                            )
                          : _SignupForm(
                              key: const ValueKey('signup'),
                              onGoLogin: () =>
                                  setState(() => _tab = AuthTab.login),
                              onRoleArt: (role) => setState(() => _signupArt =
                                  'assets/illustrations/$role.svg'),
                            ),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ log in

class _LoginForm extends StatefulWidget {
  final VoidCallback onGoSignup;
  const _LoginForm({super.key, required this.onGoSignup});

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  bool _busy = false, _remember = true;
  String? _err, _emailErr, _passErr;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  /// Accepts a real email or a bare username ("test2" -> test2@sciencelearn.local).
  String get _loginId {
    final id = _email.text.trim();
    return id.contains('@') ? id : '$id@sciencelearn.local';
  }

  Future<void> _signIn() async {
    final emailEmpty = _email.text.trim().isEmpty;
    final passEmpty = _pass.text.isEmpty;
    setState(() {
      _emailErr = emailEmpty ? 'Enter your email or username' : null;
      _passErr = passEmpty ? 'Enter your password' : null;
      _err = null;
    });
    if (emailEmpty) return _emailFocus.requestFocus();
    if (passEmpty) return _passFocus.requestFocus();

    setState(() => _busy = true);
    try {
      await Supabase.instance.client.auth
          .signInWithPassword(email: _loginId, password: _pass.text);
      // Session change makes the router redirect; sheet closes via host.
      if (mounted) Navigator.of(context).maybePop();
    } on AuthException catch (e) {
      setState(() => _err = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Password reset goes through the same Supabase email the web portal uses.
  Future<void> _forgot() async {
    final email = TextEditingController(text: _email.text.trim());
    final sent = await showDSModal<bool>(
      context,
      title: 'Reset password',
      body: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('We will email you a reset link.'),
        const SizedBox(height: DSSpacing.s3),
        DSTextField(
          label: 'Email or username',
          hint: 'Enter your email or username',
          controller: email,
          keyboardType: TextInputType.emailAddress,
        ),
      ]),
      actions: [
        DSButton(
            variant: DSButtonVariant.outline,
            size: DSButtonSize.sm,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        DSButton(
            size: DSButtonSize.sm,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Email me a link')),
      ],
    );
    if (sent != true || !mounted) return;
    try {
      var id = email.text.trim();
      if (id.isNotEmpty && !id.contains('@')) id = '$id@sciencelearn.local';
      await Supabase.instance.client.auth.resetPasswordForEmail(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Reset link sent — check your email.')));
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Column(children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Welcome back', style: DSText.h2),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Pick up where you left off.',
              style: DSText.bodySm.copyWith(color: DSColors.muted)),
        ),
        const SizedBox(height: 18),
        DSTextField(
          label: 'Email or username',
          hint: 'Enter your email or username',
          controller: _email,
          focusNode: _emailFocus,
          error: _emailErr,
          enabled: !_busy,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: 14),
        DSPasswordField(
          label: 'Password',
          hint: 'Enter your password',
          controller: _pass,
          focusNode: _passFocus,
          error: _passErr,
          enabled: !_busy,
          autofillHints: const [AutofillHints.password],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _busy ? null : _signIn(),
        ),
        Row(children: [
          Expanded(
            child: DSCheckbox(
              label: 'Remember me',
              value: _remember,
              disabled: _busy,
              onChanged: (v) => setState(() => _remember = v),
            ),
          ),
          TextButton(
            onPressed: _busy ? null : _forgot,
            style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(horizontal: 8)),
            child: Text('Forgot password?',
                style: DSText.bodySm.copyWith(
                    fontWeight: FontWeight.w600, color: DSColors.blue)),
          ),
        ]),
        if (_err != null) _ErrRow(_err!),
        const SizedBox(height: 16),
        DSButton(
          fullWidth: true,
          loading: _busy,
          onPressed: _signIn,
          child: const Text('Sign in'),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('New to ScienceLearn?',
              style: DSText.bodySm.copyWith(color: DSColors.muted)),
          TextButton(
            onPressed: _busy ? null : widget.onGoSignup,
            style: TextButton.styleFrom(
                minimumSize: const Size(44, 40),
                padding: const EdgeInsets.symmetric(horizontal: 8)),
            child: Text('Create an account',
                style: DSText.bodySm.copyWith(
                    fontWeight: FontWeight.w600, color: DSColors.blue)),
          ),
        ]),
      ]),
    );
  }
}

// ----------------------------------------------------------------- sign up

class _SignupForm extends StatefulWidget {
  final VoidCallback onGoLogin;
  final ValueChanged<String>? onRoleArt;
  const _SignupForm({super.key, required this.onGoLogin, this.onRoleArt});

  @override
  State<_SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<_SignupForm> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmFocus = FocusNode();
  String _role = 'student';
  bool _busy = false, _sent = false;
  String? _err, _nameErr, _emailErr, _passErr, _confirmErr;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final nameEmpty = _name.text.trim().isEmpty;
    final emailEmpty = _email.text.trim().isEmpty;
    final passEmpty = _pass.text.isEmpty;
    final mismatch = _pass.text != _confirm.text;
    setState(() {
      _nameErr = nameEmpty ? 'Enter your full name' : null;
      _emailErr = emailEmpty ? 'Enter your email or username' : null;
      _passErr = passEmpty ? 'Create a password' : null;
      _confirmErr = mismatch ? "Passwords don't match" : null;
      _err = null;
    });
    // First invalid field gets focus.
    if (nameEmpty) return _nameFocus.requestFocus();
    if (emailEmpty) return _emailFocus.requestFocus();
    if (passEmpty) return _passFocus.requestFocus();
    if (mismatch) return _confirmFocus.requestFocus();

    setState(() => _busy = true);
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
      if (auth.currentSession == null && mounted) {
        setState(() => _sent = true);
      } else if (mounted) {
        Navigator.of(context).maybePop();
      }
    } on AuthException catch (e) {
      setState(() => _err = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sent) {
      return Column(children: [
        const DSIcon(DSIconName.mailVerified, size: 48, color: DSColors.blue),
        const SizedBox(height: 10),
        Text('Check your email', style: DSText.h2),
        const SizedBox(height: 8),
        Text(
          'We sent a confirmation link to ${_email.text.trim()}. Open it to activate your account, then sign in.',
          textAlign: TextAlign.center,
          style: DSText.bodySm.copyWith(color: DSColors.muted, height: 1.5),
        ),
        const SizedBox(height: 16),
        TextButton(
            onPressed: widget.onGoLogin,
            child: Text('Back to Sign In',
                style: DSText.bodySm.copyWith(
                    fontWeight: FontWeight.w600, color: DSColors.blue))),
      ]);
    }

    return AutofillGroup(
      child: Column(children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Create your account', style: DSText.h2),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Join as a student or a teacher.',
              style: DSText.bodySm.copyWith(color: DSColors.muted)),
        ),
        const SizedBox(height: 18),
        DSTextField(
          label: 'Full name',
          hint: 'Enter your full name',
          controller: _name,
          focusNode: _nameFocus,
          error: _nameErr,
          enabled: !_busy,
          autofillHints: const [AutofillHints.name],
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 11),
        DSTextField(
          label: 'Email or username',
          hint: 'Enter your email or username',
          controller: _email,
          focusNode: _emailFocus,
          error: _emailErr,
          enabled: !_busy,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: 11),
        DSPasswordField(
          label: 'Password',
          hint: 'Create a password',
          controller: _pass,
          focusNode: _passFocus,
          error: _passErr,
          enabled: !_busy,
          autofillHints: const [AutofillHints.newPassword],
        ),
        const SizedBox(height: 11),
        DSPasswordField(
          label: 'Confirm password',
          hint: 'Re-enter your password',
          controller: _confirm,
          focusNode: _confirmFocus,
          error: _confirmErr,
          enabled: !_busy,
          autofillHints: const [AutofillHints.newPassword],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _busy ? null : _create(),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('I am a…', style: DSText.label),
        ),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            child: DSOptionTile(
              icon: DSIconName.school,
              label: 'Student',
              selected: _role == 'student',
              selectedFill: DSColors.pastelMint,
              disabled: _busy,
              onTap: () {
                setState(() => _role = 'student');
                widget.onRoleArt?.call('student');
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DSOptionTile(
              icon: DSIconName.presentation,
              label: 'Teacher',
              selected: _role == 'teacher',
              selectedFill: DSColors.pastelYellow,
              disabled: _busy,
              onTap: () {
                setState(() => _role = 'teacher');
                widget.onRoleArt?.call('teacher');
              },
            ),
          ),
        ]),
        if (_err != null) _ErrRow(_err!),
        const SizedBox(height: 14),
        DSButton(
          fullWidth: true,
          loading: _busy,
          onPressed: _create,
          child: const Text('Create account'),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Already have an account?',
              style: DSText.bodySm.copyWith(color: DSColors.muted)),
          TextButton(
            onPressed: _busy ? null : widget.onGoLogin,
            style: TextButton.styleFrom(
                minimumSize: const Size(44, 40),
                padding: const EdgeInsets.symmetric(horizontal: 8)),
            child: Text('Log in',
                style: DSText.bodySm.copyWith(
                    fontWeight: FontWeight.w600, color: DSColors.blue)),
          ),
        ]),
      ]),
    );
  }
}

/// Shared inline error row — alert icon + coral message.
class _ErrRow extends StatelessWidget {
  final String text;
  const _ErrRow(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(children: [
        const DSIcon(DSIconName.alert, size: 16, color: DSColors.error),
        const SizedBox(width: 6),
        Expanded(
          child:
              Text(text, style: DSText.bodySm.copyWith(color: DSColors.error)),
        ),
      ]),
    );
  }
}
