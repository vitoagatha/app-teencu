import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class AuthForm extends StatefulWidget {
  const AuthForm(
      {super.key,
      required this.auth,
      this.register = false,
      required this.onSwitch});

  final AuthService auth;
  final bool register;
  final VoidCallback onSwitch;

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailKey = GlobalKey<FormFieldState<String>>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _busy = false;
  bool _hidePassword = true;
  bool _hideConfirmation = true;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit({bool reset = false}) async {
    if (_busy) return;
    final valid = reset
        ? _emailKey.currentState!.validate()
        : _formKey.currentState!.validate();
    if (!valid) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final email = _email.text.trim();
      if (reset) {
        await widget.auth.resetPassword(email);
        if (mounted) {
          setState(() => _message =
              'Jika email terdaftar, tautan reset password akan dikirim. '
                  'Periksa kotak masuk dan folder spam.');
        }
      } else if (widget.register) {
        await widget.auth.signUp(email, _password.text);
      } else {
        await widget.auth.signIn(email, _password.text);
      }
      // AuthGate handles navigation from the Firebase session stream.
    } catch (error) {
      if (mounted) setState(() => _message = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.register
                              ? 'Buat akun Teencu'
                              : 'Selamat datang kembali!',
                          style: const TextStyle(
                              fontSize: 30, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          key: _emailKey,
                          controller: _email,
                          enabled: !_busy,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty) {
                              return 'Isi email terlebih dahulu.';
                            }
                            if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                .hasMatch(email)) {
                              return 'Masukkan alamat email yang valid.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _password,
                          enabled: !_busy,
                          obscureText: _hidePassword,
                          autocorrect: false,
                          enableSuggestions: false,
                          autofillHints: [
                            widget.register
                                ? AutofillHints.newPassword
                                : AutofillHints.password
                          ],
                          textInputAction: widget.register
                              ? TextInputAction.next
                              : TextInputAction.done,
                          onFieldSubmitted:
                              widget.register ? null : (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _hidePassword
                                  ? 'Tampilkan password'
                                  : 'Sembunyikan password',
                              onPressed: _busy
                                  ? null
                                  : () => setState(
                                      () => _hidePassword = !_hidePassword),
                              icon: Icon(_hidePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Isi password terlebih dahulu.';
                            }
                            if (widget.register && value.length < 6) {
                              return 'Password minimal 6 karakter.';
                            }
                            return null;
                          },
                        ),
                        if (widget.register) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmation,
                            enabled: !_busy,
                            obscureText: _hideConfirmation,
                            autocorrect: false,
                            enableSuggestions: false,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'Konfirmasi password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _hideConfirmation
                                    ? 'Tampilkan konfirmasi password'
                                    : 'Sembunyikan konfirmasi password',
                                onPressed: _busy
                                    ? null
                                    : () => setState(() =>
                                        _hideConfirmation = !_hideConfirmation),
                                icon: Icon(_hideConfirmation
                                    ? Icons.visibility
                                    : Icons.visibility_off),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ulangi password terlebih dahulu.';
                              }
                              return value == _password.text
                                  ? null
                                  : 'Konfirmasi password tidak sama.';
                            },
                          ),
                        ] else
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed:
                                  _busy ? null : () => _submit(reset: true),
                              child: const Text('Lupa password?'),
                            ),
                          ),
                        if (_message != null) ...[
                          const SizedBox(height: 16),
                          Semantics(liveRegion: true, child: Text(_message!)),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _busy ? null : () => _submit(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _busy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : Text(widget.register ? 'Daftar' : 'Login'),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _busy ? null : widget.onSwitch,
                          child: Text(widget.register
                              ? 'Sudah punya akun? Login'
                              : 'Belum punya akun? Daftar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
