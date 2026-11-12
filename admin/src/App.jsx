import { useState } from 'react';
import { getFirebaseServices } from './lib/firebase.js';
import { createAdminAccess } from './services/adminAccess.js';
import { AdminSessionProvider } from './auth/AdminSessionProvider.jsx';
import RequireAdmin from './auth/RequireAdmin.jsx';
import OverviewPage from './pages/OverviewPage.jsx';

export default function App() {
  const [runtime] = useState(() => {
    try {
      const services = getFirebaseServices();
      return { access: createAdminAccess(services), target: services.target };
    } catch { return { error: true }; }
  });
  return <main className="setup">
    <header><a className="brand" href="/">Teencu<span>Admin</span></a></header>
    {runtime.error ? <section className="auth-panel" role="alert">
      <h1>Konfigurasi belum siap.</h1>
      <p>Periksa konfigurasi Firebase Web pada .env.local, lalu restart dashboard.</p>
    </section> : <>
      <p className="environment">{runtime.target === 'emulator' ? 'Lingkungan pengujian lokal · demo-teencu' : 'Firebase cloud · teencu-dev'}</p>
      <AdminSessionProvider access={runtime.access}>
        <RequireAdmin><OverviewPage /></RequireAdmin>
      </AdminSessionProvider>
    </>}
    <footer>Teencu · Curhat tanpa takut dihakimi.</footer>
  </main>;
}
