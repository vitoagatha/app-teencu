import { useAdminSession } from '../auth/AdminSessionProvider.jsx';

export default function OverviewPage() {
  const { session, controller } = useAdminSession();
  return <section className="auth-panel" key={session.user.uid}>
    <p className="eyebrow">ADMIN KONTEN</p>
    <h1>Selamat datang di Teencu.</h1>
    <p>Izin admin untuk {session.user.email || session.user.uid} sudah dikonfirmasi.</p>
    <div className="status-card"><div><h2>Ruang pengelolaan bank soal</h2>
      <p>Daftar paket dan editor pertanyaan tersedia pada tahap pengembangan berikutnya.</p>
    </div></div>
    <div className="actions"><button className="secondary" onClick={() => controller.logout()}>Keluar</button></div>
  </section>;
}
