import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SessionUser {
  const SessionUser(this.uid);

  final String uid;
}

abstract class AuthService {
  Stream<SessionUser?> authStateChanges();
  Future<void> signIn(String email, String password);
  Future<void> signUp(String email, String password);
  Future<void> resetPassword(String email);
  Future<void> signOut();
  Future<void> ensureProfile(SessionUser user);
}

class FirebaseAuthService implements AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  @override
  Stream<SessionUser?> authStateChanges() => _auth.authStateChanges().map(
        (user) => user == null ? null : SessionUser(user.uid),
      );

  @override
  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> signUp(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      // Do not reveal whether an address has an account.
      if (error.code != 'user-not-found') rethrow;
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> ensureProfile(SessionUser user) async {
    final firestore = FirebaseFirestore.instance;
    final reference = firestore.collection('users').doc(user.uid);
    // Retrying on this or another device must not overwrite an existing profile.
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists) {
        transaction.set(reference, {
          'username': 'user-${user.uid}',
          'points': 0,
          'lastMbti': '',
          'lastMbtiDate': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }
}

String authErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'invalid-credential':
      case 'invalid-login-credentials':
      case 'user-not-found':
      case 'wrong-password':
        return 'Email atau password tidak sesuai.';
      case 'email-already-in-use':
        return 'Email sudah digunakan. Silakan login atau reset password.';
      case 'weak-password':
      case 'password-does-not-meet-requirements':
        return 'Password belum memenuhi persyaratan keamanan akun.';
      case 'network-request-failed':
        return 'Koneksi bermasalah. Periksa internet lalu coba lagi.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.';
      case 'user-disabled':
        return 'Akun ini dinonaktifkan.';
      case 'operation-not-allowed':
        return 'Login email dan password belum tersedia. Hubungi pengelola.';
    }
  }
  return 'Proses belum berhasil. Silakan coba lagi.';
}
