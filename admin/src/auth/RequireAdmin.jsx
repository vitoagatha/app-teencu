import { useState } from 'react';
import { useAdminSession } from './AdminSessionProvider.jsx';
import LoginPage from '../pages/LoginPage.jsx';
import AccessDeniedPage from '../pages/AccessDeniedPage.jsx';

export default function RequireAdmin({ children }) {
  const { session, controller } = useAdminSession();
  const [retrying, setRetrying] = useState(false);
  if (session.status === 'authorized') return children;
  if (session.status === 'signed-out') return <LoginPage />;
  if (session.status === 'denied') return <AccessDeniedPage />;
  const error = ['access-error', 'session-error', 'logout-error'].includes(session.status);
  return <section className="auth-panel" aria-live="polite">
    <p className="eyebrow">AKSES ADMIN</p>
    <h1>{error ? 'Akses belum dapat diperiksa.' : session.status === 'signing-out' ? 'Keluar dari akun…' : 'Memeriksa sesi dan izin…'}</h1>
    <p>{error ? 'Periksa koneksi, lalu coba lagi. Halaman admin menunggu konfirmasi izin dari server.' : 'Tunggu sebentar.'}</p>
    {error && <div className="actions">
      <button onClick={() => controller.retry()}>Coba lagi</button>
      {session.user && <button className="secondary" disabled={retrying} onClick={async () => {
        setRetrying(true);
        await controller.logout();
        setRetrying(false);
      }}>Keluar</button>}
    </div>}
  </section>;
}
