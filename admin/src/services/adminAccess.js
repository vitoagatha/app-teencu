import { onAuthStateChanged, signInWithEmailAndPassword, signOut, setPersistence, browserSessionPersistence } from 'firebase/auth';
import { doc, onSnapshot } from 'firebase/firestore';

export function createAdminAccess({ auth, firestore }) {
  return {
    watchSession: (next, error) => onAuthStateChanged(auth, next, error),
    watchAccess: (uid, next, error) => onSnapshot(
      doc(firestore, 'content_admins', uid),
      { includeMetadataChanges: true },
      (snapshot) => next({
        confirmed: !snapshot.metadata.fromCache && !snapshot.metadata.hasPendingWrites,
        enabled: snapshot.exists() && snapshot.data().enabled === true,
      }),
      error,
    ),
    async login(email, password) {
      await setPersistence(auth, browserSessionPersistence);
      await signInWithEmailAndPassword(auth, email.trim(), password);
    },
    logout: () => signOut(auth),
  };
}

export function loginErrorMessage(error) {
  switch (error?.code) {
    case 'auth/invalid-email': return 'Format email tidak valid.';
    case 'auth/invalid-credential':
    case 'auth/invalid-login-credentials':
    case 'auth/user-not-found':
    case 'auth/wrong-password': return 'Email atau password tidak sesuai.';
    case 'auth/user-disabled': return 'Akun ini dinonaktifkan.';
    case 'auth/too-many-requests': return 'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.';
    case 'auth/network-request-failed': return 'Koneksi bermasalah. Periksa internet lalu coba lagi.';
    default: return 'Login belum berhasil. Silakan coba lagi.';
  }
}
