import { CButton } from '@coreui/react';
import { useAdminSession } from '../auth/AdminSessionProvider.jsx';

export default function AccessDeniedPage() {
  const { session, controller } = useAdminSession();
  return <section className="auth-panel">
    <p className="eyebrow">AKSES TERBATAS</p>
    <h1>Akun ini belum memiliki izin admin.</h1>
    <p>{session.user.email || 'Akun yang digunakan'} sudah masuk. Hubungi pemilik proyek untuk mendapatkan akses pengelolaan konten.</p>
    <div className="actions">
      <CButton color="primary" onClick={() => controller.logout()}>Keluar / ganti akun</CButton>
      <CButton color="secondary" variant="outline" onClick={() => controller.retry()}>Periksa izin lagi</CButton>
    </div>
  </section>;
}
