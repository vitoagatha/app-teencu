import { CButton, CFormInput, CForm } from '@coreui/react';
import { useEffect, useRef, useState } from 'react';
import { CCard, CCardBody } from '@coreui/react';
import { BankStatus, formatDate } from '../components/BankMetadata.jsx';

export default function BankDetailPage({ id, repository, onBack, onSelect }) {
  const [result, setResult] = useState({ loading: true });
  const [revision, setRevision] = useState(0);
  const [copying, setCopying] = useState(false);
  const [error, setError] = useState('');
  const [newId, setNewId] = useState('');
  const [title, setTitle] = useState('');
  const [version, setVersion] = useState('');
  const pending = useRef(false);
  const mounted = useRef(false);
  useEffect(() => { mounted.current = true; return () => { mounted.current = false; }; }, []);
  useEffect(() => {
    let current = true;
    setResult({ loading: true });
    repository.loadDetail(id).then((bank) => { if (current) { setResult({ bank }); setTitle(bank.title); } })
      .catch(() => { if (current) setResult({ error: true }); });
    return () => { current = false; };
  }, [id, repository, revision]);
  async function copy(event) {
    event.preventDefault();
    if (pending.current) return;
    pending.current = true;
    setCopying(true); setError('');
    try { await repository.copyToDraft(id, newId.trim(), title, version); if (mounted.current) onSelect(newId.trim()); }
    catch (cause) { if (mounted.current) setError(cause.code ? 'Draft belum dapat disimpan. Periksa koneksi dan izin admin. Jika ID sudah ada, buka paket tersebut untuk memeriksa hasilnya.' : cause.message); }
    finally { pending.current = false; if (mounted.current) setCopying(false); }
  }
  return <>
    <CButton color="secondary" variant="outline" disabled={copying} onClick={onBack}>Kembali ke daftar</CButton>
    {result.loading ? <p role="status">Memuat detail…</p> : result.error ? <div role="alert"><p>Paket tidak ditemukan, tidak valid, atau belum dapat dimuat.</p><CButton color="primary" onClick={() => setRevision((v) => v + 1)}>Coba lagi</CButton></div> : <>
      <h1>{result.bank.title}</h1><BankStatus bank={result.bank} />
      <dl className="bank-meta"><dt>ID paket</dt><dd>{id}</dd><dt>Versi</dt><dd>{result.bank.version}</dd><dt>Algoritma</dt><dd>{result.bank.scoringVersion}</dd><dt>Dibuat</dt><dd>{formatDate(result.bank.createdAt)}</dd><dt>Dipublikasikan</dt><dd>{formatDate(result.bank.publishedAt)}</dd></dl>
      <h2>{result.bank.questions.length} pertanyaan</h2>
      <ol className="question-list">{result.bank.questions.map((q) => <li key={q.id}><p>{q.text}</p><small>{q.id} · Setuju mengarah ke {q.agreeWith}</small></li>)}</ol>
      <CCard className="copy-panel shadow-sm"><CCardBody><h2>Salin menjadi draft baru</h2><p>Paket asal tetap tersimpan. Salinan tidak langsung menjadi versi aktif. Editor pertanyaan tersedia pada tahap berikutnya.</p>
        <CForm onSubmit={copy}><fieldset disabled={copying}>
          <label htmlFor="new-id">ID paket baru</label><CFormInput id="new-id" required maxLength={80} pattern="[a-zA-Z0-9_-]+" placeholder="mbti-v2" value={newId} onChange={(e) => setNewId(e.target.value)} />
          <label htmlFor="copy-title">Judul</label><CFormInput id="copy-title" required maxLength={160} value={title} onChange={(e) => setTitle(e.target.value)} />
          <label htmlFor="copy-version">Label versi baru</label><CFormInput id="copy-version" required maxLength={80} placeholder="v2" value={version} onChange={(e) => setVersion(e.target.value)} />
          {error && <p role="alert" className="config-error">{error}</p>}<CButton color="primary" type="submit">{copying ? 'Menyimpan…' : 'Simpan salinan draft'}</CButton>
        </fieldset></CForm>
      </CCardBody></CCard>
    </>}
  </>;
}
