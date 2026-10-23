import 'package:flutter/material.dart';

import 'services/auth_service.dart';
import 'sign_up.dart';
import 'widgets/auth_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key, required this.auth});

  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    return AuthForm(
      auth: auth,
      onSwitch: () => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => SignUpPage(auth: auth),
      )),
    );
  }
}
