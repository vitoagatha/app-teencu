import { CButton } from '@coreui/react';
import { useState } from 'react';
import { CCard, CCardBody, CContainer } from '@coreui/react';
import { useAdminSession } from './AdminSessionProvider.jsx';
import LoginPage from '../pages/LoginPage.jsx';
import AccessDeniedPage from '../pages/AccessDeniedPage.jsx';

export default function RequireAdmin({ children, environment }) {
  const { session, controller } = useAdminSession();
  const [retrying, setRetrying] = useState(false);
  if (session.status === 'authorized') return children;
  const frame = (content) => <main className="auth-shell"><CContainer><div className="auth-brand">Teencu <span>Admin</span></div><div className="text-center mb-4">{environment}</div><CCard className="auth-card shadow-sm mx-auto"><CCardBody className="p-4 p-md-5">{content}</CCardBody></CCard><p className="text-center text-body-secondary small mt-4">Curhat tanpa takut dihakimi.</p></CContainer></main>;
  if (session.status === 'signed-out') return frame(<LoginPage />);
  if (session.status === 'denied') return frame(<AccessDeniedPage />);
  const error = ['access-error', 'session-error', 'logout-error'].includes(session.status);
  return frame(<section className="auth-panel" aria-live="polite">
    <p className="eyebrow">AKSES ADMIN</p>
    <h1>{error ? 'Akses belum dapat diperiksa.' : session.status === 'signing-out' ? 'Keluar dari akun…' : 'Memeriksa sesi dan izin…'}</h1>
    <p>{error ? 'Periksa koneksi, lalu coba lagi. Halaman admin menunggu konfirmasi izin dari server.' : 'Tunggu sebentar.'}</p>
    {error && <div className="actions">
      <CButton color="primary" onClick={() => controller.retry()}>Coba lagi</CButton>
      {session.user && <CButton color="secondary" variant="outline" disabled={retrying} onClick={async () => {
        setRetrying(true);
        await controller.logout();
        setRetrying(false);
      }}>Keluar</CButton>}
    </div>}
  </section>);
}
