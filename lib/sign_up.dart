import 'package:flutter/material.dart';

import 'services/auth_service.dart';
import 'widgets/auth_form.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key, required this.auth});

  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    return AuthForm(
      auth: auth,
      register: true,
      onSwitch: () => Navigator.of(context).pop(),
    );
  }
}
