import { useEffect, useRef, useState } from 'react';
import { CAlert, CButton, CCard, CCardBody, CModal, CModalBody, CModalFooter, CModalHeader, CModalTitle } from '@coreui/react';

export default function PublicationActions({ bank, repository, onUpdated, onBusyChange, disabled = false }) {
  const [confirmation, setConfirmation] = useState(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');
  const pending = useRef(false);
  const alive = useRef(false);
  useEffect(() => { alive.current = true; return () => { alive.current = false; }; }, []);
  async function prepare() {
    if (pending.current) return;
    pending.current = true; setBusy(true); onBusyChange(true); setError(''); setMessage('');
    try {
      const context = await repository.prepareActivation(bank.id);
      if (!alive.current) return;
      setConfirmation({ action: 'activate', context });
    } catch (cause) { if (alive.current) setError(cause.code ? 'Versi aktif belum dapat diperiksa. Periksa koneksi dan izin, lalu coba lagi.' : cause.message); }
    finally { pending.current = false; if (alive.current) { setBusy(false); onBusyChange(false); } }
  }
  async function confirm() {
    if (pending.current || !confirmation) return;
    pending.current = true; setBusy(true); onBusyChange(true); setError(''); setMessage('');
    const action = confirmation.action;
    try {
      if (action === 'publish') await repository.publish(bank);
      else await repository.activate(confirmation.context);
      if (!alive.current) return;
      setConfirmation(null);
      setMessage(action === 'publish' ? 'Paket berhasil dipublikasikan. Versi aktif belum diubah.' : 'Versi aktif berhasil dikonfirmasi. Tes baru menggunakan paket ini.');
      onUpdated(action === 'publish' ? 'Paket berhasil dipublikasikan. Versi aktif belum diubah.' : 'Versi aktif berhasil dikonfirmasi. Tes baru menggunakan paket ini.');
    } catch (cause) {
      if (alive.current) {
        setConfirmation(null);
        setError(cause.code ? 'Operasi belum dapat dikonfirmasi. Periksa koneksi/izin lalu muat ulang status sebelum mencoba lagi; perubahan mungkin sudah tersimpan.' : cause.message);
      }
    } finally { pending.current = false; if (alive.current) { setBusy(false); onBusyChange(false); } }
  }
  return <CCard className="my-4"><CCardBody>
    <h2>Publikasi dan versi aktif</h2>
    <p>{bank.status === 'draft' ? 'Publish mengunci paket tersimpan ini. Aktivasi dilakukan terpisah setelah publikasi.' : 'Aktifkan paket ini untuk tes baru. Versi published lama juga dapat dipilih kembali.'}</p>
    {error && <CAlert color="danger" role="alert">{error}</CAlert>}
    {message && <CAlert color="success" role="status">{message}</CAlert>}
    <div className="actions mt-0">{bank.status === 'draft'
      ? <CButton color="primary" disabled={busy || disabled} onClick={() => { setError(''); setMessage(''); setConfirmation({ action: 'publish' }); }}>Publish paket</CButton>
      : <CButton color="primary" disabled={busy || disabled} onClick={prepare}>{busy ? 'Memeriksa…' : 'Aktifkan versi ini'}</CButton>}</div>
    <CModal visible={Boolean(confirmation)} backdrop="static" keyboard={!busy} onClose={() => { if (!pending.current) setConfirmation(null); }} aria-labelledby="publication-title">
      <CModalHeader closeButton={!busy}><CModalTitle id="publication-title">{confirmation?.action === 'publish' ? 'Konfirmasi publikasi' : 'Konfirmasi versi aktif'}</CModalTitle></CModalHeader>
      <CModalBody>{confirmation?.action === 'publish' ? <>
        <p><strong>{bank.title}</strong><br />ID: {bank.id} · Versi {bank.version} · {bank.questions.length} soal</p>
        <CAlert color="warning">Setelah published, paket tidak dapat diedit atau dihapus melalui dashboard. Versi aktif tidak otomatis berubah.</CAlert>
      </> : confirmation ? <>
        <p>Versi aktif saat ini: <strong>{confirmation.context.current ? `${confirmation.context.current.title} (${confirmation.context.current.version})` : confirmation.context.pointer ? 'Paket aktif tidak dapat dijelaskan' : 'Belum ada'}</strong><br />ID: {confirmation.context.pointer?.testId || '—'}</p>
        <p>Tujuan: <strong>{confirmation.context.target.title} ({confirmation.context.target.version})</strong><br />ID: {confirmation.context.target.id} · {confirmation.context.target.questions.length} soal</p>
        <p>{confirmation.context.pointer?.testId === bank.id ? 'Paket ini sudah aktif. Konfirmasi tidak akan mengganti pointer yang sama.' : 'Tes yang baru dimulai akan memakai paket tujuan. Sesi berjalan dan riwayat lama tetap memakai versi asalnya.'}</p>
      </> : null}</CModalBody>
      <CModalFooter><CButton color="secondary" variant="outline" disabled={busy} onClick={() => setConfirmation(null)}>Batal</CButton><CButton color="primary" disabled={busy} onClick={confirm}>{busy ? 'Memproses…' : confirmation?.action === 'publish' ? 'Ya, publish paket' : 'Ya, aktifkan versi'}</CButton></CModalFooter>
    </CModal>
  </CCardBody></CCard>;
}
