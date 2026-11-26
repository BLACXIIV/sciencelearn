import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../landing/landing_screen.dart';
import 'auth_sheet.dart';

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
