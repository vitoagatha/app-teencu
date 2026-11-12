import { CButton, CFormCheck, CFormInput, CForm } from '@coreui/react';
import { useRef, useState } from 'react';
import { useAdminSession } from '../auth/AdminSessionProvider.jsx';
import { loginErrorMessage } from '../services/adminAccess.js';

export default function LoginPage() {
  const { access } = useAdminSession();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [visible, setVisible] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const pending = useRef(false);
  async function submit(event) {
    event.preventDefault();
    if (pending.current) return;
    if (!email.trim() || !password) { setError('Isi email dan password terlebih dahulu.'); return; }
    pending.current = true;
    setBusy(true);
    setError('');
    try { await access.login(email, password); }
    catch (cause) { setError(loginErrorMessage(cause)); }
    finally { pending.current = false; setBusy(false); }
  }
  return <section className="auth-panel" aria-labelledby="login-title">
    <p className="eyebrow">RUANG PENGELOLAAN KONTEN</p>
    <h1 id="login-title">Selamat datang kembali.</h1>
    <p>Masuk dengan akun yang memiliki izin admin konten Teencu.</p>
    <CForm onSubmit={submit} aria-busy={busy}>
      <fieldset disabled={busy}>
        <label htmlFor="email">Email</label>
        <CFormInput id="email" type="email" autoComplete="username" required value={email} onChange={(event) => setEmail(event.target.value)} />
        <label htmlFor="password">Password</label>
        <CFormInput id="password" type={visible ? 'text' : 'password'} autoComplete="current-password" required value={password} onChange={(event) => setPassword(event.target.value)} />
        <label className="checkbox"><CFormCheck type="checkbox" checked={visible} onChange={(event) => setVisible(event.target.checked)} />Tampilkan password</label>
        {error && <p role="alert" className="config-error">{error}</p>}
        <CButton color="primary" type="submit">{busy ? 'Masuk…' : 'Masuk'}</CButton>
      </fieldset>
    </CForm>
  </section>;
}
