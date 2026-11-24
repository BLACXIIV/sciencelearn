import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../design_system/design_system.dart';
import '../landing/landing_screen.dart';

enum AuthTab { login, signup }

/// Opens the shared auth bottom sheet (Sign up tab by default).
/// Closes by drag-down, barrier tap, or Android back.
Future<void> showAuthSheet(BuildContext context,
        {AuthTab initial = AuthTab.signup}) =>
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

/// Host for the /login and /signup routes: renders the landing page and
/// immediately opens the auth sheet on the matching tab. When the sheet
/// closes without signing in, fall back to /welcome.
class AuthSheetHost extends StatefulWidget {
  final AuthTab tab;
  const AuthSheetHost({super.key, required this.tab});

  @override
  State<AuthSheetHost> createState() => _AuthSheetHostState();
}

class _AuthSheetHostState extends State<AuthSheetHost> {
  @override
  void initState() {
    super.initState();
    // Let the navigator settle before pushing the sheet (first-frame races at
    // app start can swallow the open call).
    Future.delayed(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      await showAuthSheet(context, initial: widget.tab);
      if (mounted) context.go('/welcome');
    });
  }

  @override
  Widget build(BuildContext context) => const LandingScreen();
}

/// Trivia facts for the "Did you know?" card — same list as the web portal.
const _trivia = [
  'Momentum is conserved in an isolated system, even in a collision.',
  "Honey never spoils. Archaeologists have tasted 3,000-year-old honey found in Egyptian tombs — and it's still edible.",
  'A bolt of lightning is about five times hotter than the surface of the Sun.',
  'Your body makes around 25 million new cells every single second.',
  "There are more atoms in a glass of water than there are glasses of water in all of Earth's oceans.",
  'Octopuses have three hearts — and two of them stop beating when they swim.',
  "Hot water can freeze faster than cold water. It's called the Mpemba effect, and scientists still debate why.",
];

/// Navy-top sheet: the navy area holds the Storyset art in a paper circle
/// (250px on Log in, 150px on Sign up — animated), then the white sheet
/// slides up below it. The art can never overlap the title or form.
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
    final tall = MediaQuery.sizeOf(context).height >= 700;
    return GestureDetector(
      // Tapping outside a field dismisses the keyboard.
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        // White sheet only — the SVG art sits on the dimmed backdrop behind
        // it, blurred, peeking from the sheet's top-right corner; the "Did
        // you know?" card floats above the top edge on the left.
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned(
            top: -132,
            right: -10,
            child: IgnorePointer(
              child: AnimatedSwitcher(
                duration: dur,
                child: ImageFiltered(
                  key: ValueKey(_art),
                  imageFilter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: SvgPicture.asset(_art, width: 200),
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: DSColors.surface,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(DSRadii.panel)),
              boxShadow: dsEdgeTop(DSColors.mint.withValues(alpha: .4), h: 3),
            ),
            child: SingleChildScrollView(
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
                            onRoleArt: (role) => setState(() =>
                                _signupArt = 'assets/illustrations/$role.svg'),
                          ),
                  ),
                ),
              ]),
            ),
          ),
          if (tall)
            const Positioned(
              top: -128,
              left: 16,
              right: 168,
              child: _TriviaCard(),
            ),
        ]),
      ),
    );
  }
}

/// Compact "Did you know?" trivia card for the navy zone — shown only on
/// tall viewports (≥700px). Facts rotate every 7s; tap shuffle for the next.
class _TriviaCard extends StatefulWidget {
  const _TriviaCard();

  @override
  State<_TriviaCard> createState() => _TriviaCardState();
}

class _TriviaCardState extends State<_TriviaCard> {
  int _fact = 0;
  Timer? _timer;

  void _next() => setState(() => _fact = (_fact + 1) % _trivia.length);

  @override
  void initState() {
    super.initState();
    _fact = DateTime.now().millisecond % _trivia.length;
    _timer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (mounted && !MediaQuery.disableAnimationsOf(context)) _next();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: DSCard(
        variant: DSCardVariant.trivia,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('DID YOU KNOW?',
                  style: DSText.caption
                      .copyWith(color: DSColors.blue, letterSpacing: .7)),
              const SizedBox(height: 4),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _trivia[_fact],
                  key: ValueKey(_fact),
                  style: DSText.title.copyWith(fontSize: 13, height: 1.4),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 8),
          DSIconButton(
              icon: DSIconName.retry,
              label: 'Show another fact',
              onPressed: _next),
        ]),
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
                style: DSText.label.copyWith(color: DSColors.blue)),
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
                style: DSText.label.copyWith(color: DSColors.blue)),
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
        Text('Check your email', style: DSText.h3),
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
                style: DSText.label.copyWith(color: DSColors.blue))),
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
          child: Text('I am a…', style: DSText.title),
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
                style: DSText.label.copyWith(color: DSColors.blue)),
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
