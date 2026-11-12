import { useAdminSession } from '../auth/AdminSessionProvider.jsx';

export default function AccessDeniedPage() {
  const { session, controller } = useAdminSession();
  return <section className="auth-panel">
    <p className="eyebrow">AKSES TERBATAS</p>
    <h1>Akun ini belum memiliki izin admin.</h1>
    <p>{session.user.email || 'Akun yang digunakan'} sudah masuk. Hubungi pemilik proyek untuk mendapatkan akses pengelolaan konten.</p>
    <div className="actions">
      <button onClick={() => controller.logout()}>Keluar / ganti akun</button>
      <button className="secondary" onClick={() => controller.retry()}>Periksa izin lagi</button>
    </div>
  </section>;
}
