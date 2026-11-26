import 'package:flutter/material.dart';

import 'auth_sheet.dart';

/// /login route — opens the shared auth sheet on the Log in tab.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) => const AuthSheetHost(tab: AuthTab.login);
}
