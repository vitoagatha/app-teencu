import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teencu/auth_gate.dart';
import 'package:teencu/services/auth_service.dart';
import 'package:teencu/sign_in.dart';
import 'package:teencu/sign_up.dart';

class FakeAuth implements AuthService {
  final sessions = StreamController<SessionUser?>.broadcast();
  final calls = <String>[];
  String? email;
  String? password;
  Object? failure;
  Object? profileFailure;
  Completer<void>? pending;

  @override
  Stream<SessionUser?> authStateChanges() => sessions.stream;

  Future<void> _request(String action, String address, [String? secret]) async {
    calls.add(action);
    email = address;
    password = secret;
    if (failure != null) throw failure!;
    if (pending != null) await pending!.future;
  }

  @override
  Future<void> signIn(String email, String password) =>
      _request('login', email, password);
  @override
  Future<void> signUp(String email, String password) =>
      _request('signup', email, password);
  @override
  Future<void> resetPassword(String email) => _request('reset', email);
  @override
  Future<void> signOut() async => sessions.add(null);
  @override
  Future<void> ensureProfile(SessionUser user) async {
    calls.add('profile:${user.uid}');
    if (profileFailure != null) throw profileFailure!;
  }
}

void main() {
  late FakeAuth auth;

  setUp(() => auth = FakeAuth());
  tearDown(() => auth.sessions.close());

  testWidgets('Empty and invalid login fields never call authentication',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: LoginPage(auth: auth)));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump();
    expect(find.text('Isi email terlebih dahulu.'), findsOneWidget);
    expect(find.text('Isi password terlebih dahulu.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'not-an-email');
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump();
    expect(find.text('Masukkan alamat email yang valid.'), findsOneWidget);
    expect(auth.calls, isEmpty);
  });

  testWidgets(
      'Login trims email, preserves password, and prevents duplicate submits',
      (tester) async {
    auth.pending = Completer<void>();
    await tester.pumpWidget(MaterialApp(home: LoginPage(auth: auth)));
    await tester.enterText(
        find.byType(TextFormField).at(0), ' person@example.com ');
    await tester.enterText(find.byType(TextFormField).at(1), ' pass word ');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
    expect(auth.calls, ['login']);
    expect(auth.email, 'person@example.com');
    expect(auth.password, ' pass word ');
    auth.pending!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('Signup validates confirmation and displays Firebase errors',
      (tester) async {
    auth.failure = FirebaseAuthException(code: 'email-already-in-use');
    await tester.pumpWidget(MaterialApp(home: SignUpPage(auth: auth)));
    await tester.enterText(
        find.byType(TextFormField).at(0), 'person@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.enterText(find.byType(TextFormField).at(2), 'different');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Daftar'));
    await tester.pump();
    expect(auth.calls, isEmpty);
    expect(find.text('Konfirmasi password tidak sama.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(2), 'password');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Daftar'));
    await tester.pumpAndSettle();
    expect(auth.calls, ['signup']);
    expect(
        find.text('Email sudah digunakan. Silakan login atau reset password.'),
        findsOneWidget);
    expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNotNull);
  });

  testWidgets('Reset requires email but does not require a password',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: LoginPage(auth: auth)));
    await tester.tap(find.text('Lupa password?'));
    await tester.pump();
    expect(auth.calls, isEmpty);
    await tester.enterText(
        find.byType(TextFormField).first, 'person@example.com');
    await tester.tap(find.text('Lupa password?'));
    await tester.pumpAndSettle();
    expect(auth.calls, ['reset']);
    expect(find.textContaining('Jika email terdaftar'), findsOneWidget);
  });

  testWidgets('Password visibility toggle works', (tester) async {
    await tester.pumpWidget(MaterialApp(home: LoginPage(auth: auth)));
    expect(tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
        isTrue);
    await tester.tap(find.byTooltip('Tampilkan password'));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
        isFalse);
  });

  testWidgets('Signup fits a small viewport with keyboard open',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(
            size: Size(360, 640), viewInsets: EdgeInsets.only(bottom: 280)),
        child: SignUpPage(auth: auth),
      ),
    ));
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Daftar'));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Restored session retries profile without registering another account',
      (tester) async {
    auth.profileFailure = Exception('offline');
    await tester.pumpWidget(MaterialApp(
        home: AuthGate(
      auth: auth,
      homeBuilder: (_) => const Scaffold(body: Text('Home ready')),
    )));
    auth.sessions.add(const SessionUser('user-a'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('tidak perlu membuat akun baru'), findsOneWidget);
    auth.profileFailure = null;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Home ready'), findsOneWidget);
    expect(auth.calls, ['profile:user-a', 'profile:user-a']);
  });

  testWidgets('Session changes discard registration and all private routes',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: AuthGate(
      auth: auth,
      homeBuilder: (context) => Scaffold(
          body: TextButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Private profile')),
        )),
        child: const Text('Open profile'),
      )),
    )));
    auth.sessions.add(null);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Belum punya akun? Daftar'));
    await tester.pumpAndSettle();
    expect(find.text('Buat akun Teencu'), findsOneWidget);
    auth.sessions.add(const SessionUser('user-a'));
    await tester.pumpAndSettle();
    expect(find.text('Buat akun Teencu'), findsNothing);
    await tester.tap(find.text('Open profile'));
    await tester.pumpAndSettle();
    expect(find.text('Private profile'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Open profile'), findsOneWidget);
    await tester.tap(find.text('Open profile'));
    await tester.pumpAndSettle();
    await auth.signOut();
    await tester.pumpAndSettle();
    expect(find.text('Selamat datang kembali!'), findsOneWidget);
    expect(find.text('Private profile'), findsNothing);
    final context = tester.element(find.text('Selamat datang kembali!'));
    expect(Navigator.of(context).canPop(), isFalse);
  });
}
