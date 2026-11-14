import { useEffect, useRef, useState } from 'react';
import { CAlert, CButton, CCard, CCardBody, CForm, CFormInput, CFormSelect, CFormTextarea } from '@coreui/react';
import { draftContent, fingerprint, moveQuestion, validateDraft } from '../domain/mbtiDraft.js';
import { createPreview } from '../domain/mbtiScoring.js';
import BankPreviewPage from './BankPreviewPage.jsx';

const emptyDraft = () => ({ title: '', version: '', questions: ['E', 'S', 'T', 'J'].map((agreeWith) => ({ id: `q-${crypto.randomUUID()}`, text: '', agreeWith })) });
export default function BankEditorPage({ id, repository, onBack, onCreated, registerGuard }) {
  const [baseline, setBaseline] = useState(null);
  const [preview, setPreview] = useState(null);
  const [form, setForm] = useState(emptyDraft);
  const [newId, setNewId] = useState('');
  const [loading, setLoading] = useState(Boolean(id));
  const [loadError, setLoadError] = useState('');
  const [revision, setRevision] = useState(0);
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');
  const pending = useRef(false);
  const alive = useRef(false);
  const initial = useRef(fingerprint({ id: '', form: draftContent(form) }));
  const effectiveId = id || newId;
  const dirty = !loading && !loadError && (baseline
    ? fingerprint(draftContent(form)) !== fingerprint(draftContent(baseline))
    : fingerprint({ id: newId, form: draftContent(form) }) !== initial.current);
  let validation;
  try { validateDraft(effectiveId, form); } catch (cause) { validation = cause.message; }
  useEffect(() => { alive.current = true; return () => { alive.current = false; }; }, []);
  useEffect(() => {
    if (!id) return;
    let current = true;
    setLoading(true); setLoadError('');
    repository.loadDetail(id).then((bank) => {
      if (!current) return;
      if (bank.status !== 'draft') { setLoadError('Paket published terkunci. Buat salinan draft dari halaman detail.'); return; }
      setBaseline(bank); setForm(draftContent(bank)); setError(''); setMessage('');
    }).catch(() => { if (current) setLoadError('Draft belum dapat dimuat. Periksa koneksi dan izin admin.'); })
      .finally(() => { if (current) setLoading(false); });
    return () => { current = false; };
  }, [id, repository, revision]);
  const guardState = useRef({ dirty, busy });
  guardState.current = { dirty, busy };
  useEffect(() => {
    const guard = () => !guardState.current.busy && (!guardState.current.dirty || window.confirm('Perubahan belum disimpan. Tinggalkan editor?'));
    registerGuard(guard);
    return () => registerGuard(null);
  }, [registerGuard]);
  useEffect(() => {
    const warn = (event) => { if (guardState.current.dirty || guardState.current.busy) { event.preventDefault(); event.returnValue = ''; } };
    window.addEventListener('beforeunload', warn);
    return () => window.removeEventListener('beforeunload', warn);
  }, []);
  function edit(update) { setMessage(''); setError(''); setForm((previous) => ({ ...previous, ...update })); }
  function question(index, field, value) {
    edit({ questions: form.questions.map((q, i) => i === index ? { ...q, [field]: value } : q) });
  }
  async function save(event) {
    event.preventDefault();
    if (pending.current || validation || !dirty) return;
    pending.current = true; setBusy(true); setMessage(''); setError('');
    try {
      const saved = await repository.saveDraft(effectiveId, form, baseline);
      if (!alive.current) return;
      if (!id) { guardState.current = { dirty: false, busy: false }; onCreated(effectiveId); return; }
      setBaseline(saved); setForm(draftContent(saved)); setMessage('Draft berhasil disimpan.');
    } catch (cause) {
      if (alive.current) setError(cause.code ? 'Draft belum dapat disimpan. Periksa koneksi dan izin. Jika hasil simpan tidak pasti, muat ulang untuk memeriksa data server.' : cause.message);
    } finally { pending.current = false; if (alive.current) setBusy(false); }
  }
  const reload = () => { if (!busy && (!dirty || window.confirm('Buang perubahan lokal dan muat ulang draft dari server?'))) setRevision((v) => v + 1); };
  const openPreview = () => {
    try { setPreview(createPreview(effectiveId, draftContent(form))); }
    catch (cause) { setError(cause.message); }
  };
  if (preview) return <BankPreviewPage bank={preview} unsaved={dirty} onBack={() => setPreview(null)} />;
  return <>
    <CButton color="secondary" variant="outline" disabled={busy} onClick={onBack}>Kembali</CButton>
    <h1>{id ? 'Edit draft' : 'Buat draft baru'}</h1>
    {!loading && !loadError && <div className="mb-3"><CButton color="secondary" variant="outline" disabled={busy || Boolean(validation)} onClick={openPreview}>Pratinjau tes</CButton>{validation && <p className="small text-body-secondary mt-2">Pratinjau belum tersedia: {validation}</p>}</div>}
    {loading ? <p role="status">Memuat draft…</p> : loadError ? <CAlert color="warning"><p>{loadError}</p><CButton color="secondary" onClick={reload}>Coba lagi</CButton></CAlert> : <CForm onSubmit={save}>
      <fieldset disabled={busy}>
        <CCard className="mb-4"><CCardBody>
          <p className="text-body-secondary">{dirty ? 'Ada perubahan belum disimpan.' : 'Tidak ada perubahan lokal.'} Draft tidak langsung menjadi versi aktif.</p>
          <label htmlFor="draft-id">ID paket</label><CFormInput id="draft-id" value={effectiveId} readOnly={Boolean(id)} maxLength={80} onChange={(e) => setNewId(e.target.value)} />
          <label htmlFor="draft-title">Judul</label><CFormInput id="draft-title" maxLength={160} value={form.title} onChange={(e) => edit({ title: e.target.value })} />
          <label htmlFor="draft-version">Label versi</label><CFormInput id="draft-version" maxLength={80} value={form.version} onChange={(e) => edit({ version: e.target.value })} />
          <p className="small text-body-secondary mt-3">Algoritma: teencu-centered-v1 · {form.questions.length}/80 pertanyaan</p>
        </CCardBody></CCard>
        {form.questions.map((q, i) => <CCard className="mb-3" key={q.id}><CCardBody>
          <h2>Pertanyaan {i + 1}</h2><p className="small text-body-secondary">ID: {q.id}</p>
          <label htmlFor={`text-${q.id}`}>Teks pertanyaan {i + 1}</label><CFormTextarea id={`text-${q.id}`} rows={3} maxLength={1000} value={q.text} onChange={(e) => question(i, 'text', e.target.value)} />
          <label htmlFor={`direction-${q.id}`}>Setuju mengarah ke</label><CFormSelect id={`direction-${q.id}`} value={q.agreeWith} onChange={(e) => question(i, 'agreeWith', e.target.value)}>
            {['E', 'I', 'S', 'N', 'T', 'F', 'J', 'P'].map((letter) => <option key={letter} value={letter}>{letter}</option>)}
          </CFormSelect>
          <div className="actions"><CButton type="button" color="secondary" variant="outline" disabled={i === 0} onClick={() => edit({ questions: moveQuestion(form.questions, i, -1) })} aria-label={`Naikkan pertanyaan ${i + 1}`}>Naik</CButton>
            <CButton type="button" color="secondary" variant="outline" disabled={i === form.questions.length - 1} onClick={() => edit({ questions: moveQuestion(form.questions, i, 1) })} aria-label={`Turunkan pertanyaan ${i + 1}`}>Turun</CButton>
            <CButton type="button" color="danger" variant="outline" onClick={() => edit({ questions: form.questions.filter((_, index) => i !== index) })} aria-label={`Hapus pertanyaan ${i + 1}`}>Hapus</CButton></div>
        </CCardBody></CCard>)}
        <CButton type="button" color="secondary" variant="outline" disabled={form.questions.length >= 80} onClick={() => edit({ questions: [...form.questions, { id: `q-${crypto.randomUUID()}`, text: '', agreeWith: 'E' }] })}>Tambah pertanyaan</CButton>
        <div className="editor-save-bar mt-4 p-3 border rounded bg-white">
          {validation && <p className="text-warning-emphasis" role="status">{validation}</p>}
          {error && <CAlert color="danger" role="alert">{error}</CAlert>}{message && <CAlert color="success" role="status">{message}</CAlert>}
          <div className="actions mt-0"><CButton type="submit" color="primary" disabled={Boolean(validation) || !dirty}>{busy ? 'Menyimpan…' : 'Simpan draft'}</CButton>
            {id && <CButton type="button" color="secondary" variant="outline" onClick={reload}>Muat ulang dari server</CButton>}</div>
        </div>
      </fieldset>
    </CForm>}
  </>;
}
