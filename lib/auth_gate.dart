import 'package:flutter/material.dart';

import 'home.dart';
import 'services/auth_service.dart';
import 'sign_in.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.auth, this.homeBuilder});

  final AuthService auth;
  final WidgetBuilder? homeBuilder;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<SessionUser?> _session = widget.auth.authStateChanges();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SessionUser?>(
      stream: _session,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
                child: Text('Sesi tidak dapat dimuat. Buka ulang aplikasi.')),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final user = snapshot.data;
        // A new session replaces all routes and dialogs of the previous user.
        return _SessionNavigator(
          key: ValueKey(user?.uid),
          home: user == null
              ? LoginPage(auth: widget.auth)
              : _ProfileGate(
                  auth: widget.auth,
                  user: user,
                  homeBuilder: widget.homeBuilder ?? (_) => HomePage(),
                ),
        );
      },
    );
  }
}

class _SessionNavigator extends StatefulWidget {
  const _SessionNavigator({super.key, required this.home});

  final Widget home;

  @override
  State<_SessionNavigator> createState() => _SessionNavigatorState();
}

class _SessionNavigatorState extends State<_SessionNavigator> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return NavigatorPopHandler(
      onPopWithResult: (result) => _navigatorKey.currentState!.pop(result),
      child: Navigator(
        key: _navigatorKey,
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => widget.home,
        ),
      ),
    );
  }
}

class _ProfileGate extends StatefulWidget {
  const _ProfileGate({
    required this.auth,
    required this.user,
    required this.homeBuilder,
  });

  final AuthService auth;
  final SessionUser user;
  final WidgetBuilder homeBuilder;

  @override
  State<_ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<_ProfileGate> {
  late Future<void> _profile = _loadProfile();
  bool _signingOut = false;

  Future<void> _loadProfile() => widget.auth
      .ensureProfile(widget.user)
      .timeout(const Duration(seconds: 20));

  Future<void> _logout() async {
    setState(() => _signingOut = true);
    try {
      await widget.auth.signOut();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authErrorMessage(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Menyiapkan profil...'),
                ],
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Kamu sudah login, tetapi profil belum dapat dimuat. '
                        'Periksa koneksi lalu coba lagi. '
                        'Kamu tidak perlu membuat akun baru.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _signingOut
                            ? null
                            : () {
                                setState(() {
                                  _profile = _loadProfile();
                                });
                              },
                        child: const Text('Coba lagi'),
                      ),
                      TextButton(
                        onPressed: _signingOut ? null : _logout,
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        return widget.homeBuilder(context);
      },
    );
  }
}
