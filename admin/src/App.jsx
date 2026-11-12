import { useState } from 'react';
import { CBadge } from '@coreui/react';
import { getFirebaseServices } from './lib/firebase.js';
import { createAdminAccess } from './services/adminAccess.js';
import { AdminSessionProvider } from './auth/AdminSessionProvider.jsx';
import RequireAdmin from './auth/RequireAdmin.jsx';
import BankWorkspace from './components/BankWorkspace.jsx';

export default function App() {
  const [runtime] = useState(() => {
    try {
      const services = getFirebaseServices();
      return { access: createAdminAccess(services), target: services.target };
    } catch { return { error: true }; }
  });
  return <div className="app-root">
    {runtime.error ? <section className="auth-panel" role="alert">
      <h1>Konfigurasi belum siap.</h1>
      <p>Periksa konfigurasi Firebase Web pada .env.local, lalu restart dashboard.</p>
    </section> : <>
      <AdminSessionProvider access={runtime.access}>
        <RequireAdmin environment={<CBadge color={runtime.target === 'emulator' ? 'warning' : 'info'} textBgColor={runtime.target === 'emulator' ? 'warning' : 'info'}>{runtime.target === 'emulator' ? 'Emulator · demo-teencu' : 'Cloud · teencu-dev'}</CBadge>}>
          <BankWorkspace target={runtime.target} />
        </RequireAdmin>
      </AdminSessionProvider>
    </>}
  </div>;
}
