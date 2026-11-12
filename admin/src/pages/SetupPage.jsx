import { resolveFirebaseConfig } from '../lib/firebaseConfig.js';

export default function SetupPage() {
  let configuration;
  let error;
  try {
    configuration = resolveFirebaseConfig(import.meta.env);
  } catch (cause) {
    error = cause.message;
  }
  return (
    <main className="setup">
      <header><a className="brand" href="/">Teencu<span>Admin</span></a></header>
      <section className="intro" aria-labelledby="page-title">
        <p className="eyebrow">RUANG PENGELOLAAN KONTEN</p>
        <h1 id="page-title">Pertanyaan yang baik,<br />awal mengenal diri.</h1>
        <p className="description">Dashboard pengelolaan bank soal MBTI Teencu sedang disiapkan.</p>
        <div className="status-card">
          <span className="status-dot" aria-hidden="true" />
          <div>
            <h2>Fondasi dashboard siap</h2>
            <p>Login admin dan pengelolaan soal akan tersedia pada tahap berikutnya.</p>
          </div>
        </div>
        {error ? <p className="config-error" role="alert">{error}</p> : (
          <p className="environment">Konfigurasi: {configuration.target === 'emulator' ? 'Emulator lokal' : 'Firebase cloud'} · {configuration.config.projectId}<br />Koneksi dan hak akses belum diperiksa.</p>
        )}
      </section>
      <footer>Teencu · Curhat tanpa takut dihakimi.</footer>
    </main>
  );
}
