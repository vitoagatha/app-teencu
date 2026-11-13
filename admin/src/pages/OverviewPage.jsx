import { CButton } from '@coreui/react';
import { useEffect, useState } from 'react';
import { CCard, CCardBody } from '@coreui/react';
import BankListPage from './BankListPage.jsx';

export default function OverviewPage({ repository, onSelect, onCreate }) {
  const [revision, setRevision] = useState(0);
  const [active, setActive] = useState({ loading: true });
  useEffect(() => {
    let current = true;
    setActive({ loading: true });
    repository.loadActive().then((bank) => { if (current) setActive({ bank }); })
      .catch(() => { if (current) setActive({ error: true }); });
    return () => { current = false; };
  }, [repository, revision]);
  return <>
    <p className="eyebrow">PENGELOLAAN KONTEN</p><h1>Bank soal MBTI</h1>
    <p>Lihat paket pertanyaan dan versi yang digunakan untuk tes baru.</p>
    <CButton color="primary" onClick={onCreate}>Buat draft baru</CButton>
    <CCard className="status-card shadow-sm" aria-label="Versi aktif" aria-live="polite"><CCardBody>
      {active.loading ? <p>Memuat versi aktif…</p> : active.error ? <div><p role="alert">Versi aktif belum dapat dimuat. Periksa koneksi dan izin akses.</p><CButton color="secondary" variant="outline" onClick={() => setRevision((v) => v + 1)}>Coba lagi</CButton></div> : active.bank ? <div>
        <p className="eyebrow">VERSI AKTIF</p><h2>{active.bank.title}</h2><p>{active.bank.version} · {active.bank.questions.length} pertanyaan · {active.bank.id}</p>
        <CButton color="secondary" variant="outline" onClick={() => onSelect(active.bank.id)}>Lihat paket aktif</CButton>
      </div> : <div><h2>Belum ada versi aktif</h2><p>Belum ada paket yang dipilih untuk tes baru.</p></div>}
    </CCardBody></CCard>
    <div className="actions"><CButton color="secondary" variant="outline" onClick={() => setRevision((v) => v + 1)}>Muat ulang data</CButton></div>
    <BankListPage key={revision} repository={repository} activeId={active.bank?.id} onSelect={onSelect} />
  </>;
}
