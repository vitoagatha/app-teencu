import { CButton, CTable } from '@coreui/react';
import { useEffect, useState } from 'react';
import { CCard, CCardBody } from '@coreui/react';
import { BankStatus, formatDate } from '../components/BankMetadata.jsx';

export default function BankListPage({ repository, activeId, onSelect, refresh = 0, onCreate }) {
  const [cursors, setCursors] = useState([null]);
  const [revision, setRevision] = useState(0);
  const [result, setResult] = useState({ loading: true });
  const cursor = cursors.at(-1);
  useEffect(() => {
    let current = true;
    setResult({ loading: true });
    repository.loadPage(cursor).then((page) => { if (current) setResult({ page }); })
      .catch(() => { if (current) setResult({ error: true }); });
    return () => { current = false; };
  }, [repository, cursor, revision, refresh]);
  return <CCard className="bank-list shadow-sm" aria-labelledby="list-title" aria-busy={Boolean(result.loading)}><CCardBody>
    <h2 id="list-title">Daftar paket</h2><p>Terbaru berdasarkan tanggal pembuatan. Maksimal 20 paket per halaman.</p>
    {result.loading ? <p role="status">Memuat bank soal…</p> : result.error ? <div role="alert"><p>Daftar belum dapat dimuat. Coba lagi; jika tetap gagal, hubungi pengelola akses.</p><CButton color="primary" onClick={() => setRevision((v) => v + 1)}>Coba lagi</CButton></div> : <>
      <p className="page-summary">Halaman {cursors.length} · {result.page.entries.length} paket pada halaman ini</p>
      {!result.page.entries.length ? <p>Belum ada paket pada halaman ini. {cursors.length === 1 && <CButton color="primary" onClick={onCreate}>Buat draft baru</CButton>}</p> : <div className="table-scroll"><CTable hover align="middle" className="mb-0">
        <thead><tr><th>Paket</th><th>Status</th><th>Soal</th><th className="publication-date">Dipublikasikan</th></tr></thead>
        <tbody>{result.page.entries.map((bank) => <tr key={bank.id}>
          <td>{bank.invalid ? <><button className="package-link" onClick={() => onSelect(bank.id)}>Data tidak valid</button><br />{bank.id}</> : <><button className="package-link" onClick={() => onSelect(bank.id)}>{bank.title}</button><br />{bank.version} · {bank.id}</>}</td>
          <td>{bank.invalid ? 'Perlu diperiksa' : <BankStatus bank={bank} active={bank.id === activeId} />}</td>
          <td>{bank.invalid ? '—' : bank.questions.length}</td><td className="publication-date">{formatDate(bank.publishedAt)}</td>
        </tr>)}</tbody>
      </CTable></div>}
    </>}
    <div className="actions"><CButton color="secondary" variant="outline" disabled={Boolean(result.loading) || cursors.length === 1} onClick={() => setCursors((items) => items.slice(0, -1))}>Sebelumnya</CButton>
      <CButton color="secondary" variant="outline" disabled={!result.page?.hasMore || Boolean(result.loading)} onClick={() => setCursors((items) => [...items, result.page.cursor])}>Berikutnya</CButton></div>
  </CCardBody></CCard>;
}
