import 'package:flutter/material.dart';

import 'auth_sheet.dart';

/// /signup route — opens the shared auth sheet on the Sign up tab.
class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const AuthSheetHost(tab: AuthTab.signup);
}
