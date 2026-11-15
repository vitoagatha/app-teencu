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
    <div className="page-toolbar"><h1>Bank soal MBTI</h1><CButton color="primary" onClick={onCreate}>Buat draft baru</CButton></div>
    <CCard className="status-card active-summary" aria-label="Versi aktif" aria-live="polite"><CCardBody>
      {active.loading ? <p>Memuat versi aktif…</p> : active.error ? <div><p role="alert">Versi aktif belum dapat dimuat. Periksa koneksi dan izin akses.</p><CButton color="secondary" variant="outline" onClick={() => setRevision((v) => v + 1)}>Coba lagi</CButton></div> : active.bank ? <div>
        <span className="small text-body-secondary">Aktif untuk tes baru</span><h2>{active.bank.title}</h2><p>{active.bank.version} · {active.bank.questions.length} pertanyaan · {active.bank.id}</p>
        <CButton color="secondary" variant="outline" onClick={() => onSelect(active.bank.id)}>Lihat paket aktif</CButton>
      </div> : <div><h2>Belum ada versi aktif</h2><p>Belum ada paket yang dipilih untuk tes baru.</p></div>}
    </CCardBody></CCard>
    <div className="list-toolbar"><CButton color="secondary" variant="outline" onClick={() => setRevision((v) => v + 1)}>Muat ulang data</CButton></div>
    <BankListPage refresh={revision} onCreate={onCreate} repository={repository} activeId={active.bank?.id} onSelect={onSelect} />
  </>;
}
