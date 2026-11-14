import { useState } from 'react';
import { CAlert, CButton, CCard, CCardBody, CFormCheck, CProgress } from '@coreui/react';
import { calculateMbti } from '../domain/mbtiScoring.js';

const labels = ['Sangat tidak setuju', 'Tidak setuju', 'Netral', 'Setuju', 'Sangat setuju'];
const dimensions = { ei: 'E / I', sn: 'S / N', tf: 'T / F', jp: 'J / P' };
export default function BankPreviewPage({ bank, unsaved = false, onBack }) {
  const [index, setIndex] = useState(0);
  const [answers, setAnswers] = useState({});
  const [result, setResult] = useState(null);
  const [error, setError] = useState('');
  const question = bank.questions[index];
  const complete = bank.questions.every((q) => Object.hasOwn(answers, q.id));
  function calculate() {
    try { setResult(calculateMbti({ questions: bank.questions, answers })); setError(''); }
    catch (cause) { setError(cause.message); }
  }
  return <section aria-labelledby="preview-title">
    <CButton color="secondary" variant="outline" onClick={onBack}>Kembali dari pratinjau</CButton>
    <h1 id="preview-title">Pratinjau tes MBTI</h1>
    <p>{bank.title} · {bank.version} · {bank.questions.length} soal</p>
    <CAlert color="info">Simulasi admin. Jawaban dan hasil hanya ada di layar ini; tidak disimpan ke profil atau riwayat pengguna.</CAlert>
    {unsaved && <CAlert color="warning">Menggunakan perubahan editor yang belum disimpan.</CAlert>}
    {result ? <CCard><CCardBody>
      <h2>{result.type ? `Hasil simulasi: ${result.type}` : 'Hasil masih seimbang'}</h2>
      {!result.type && <p>Dimensi {result.tiedDimensions.map((d) => dimensions[d]).join(', ')} masih seimbang. Belum ada tipe empat huruf yang ditentukan.</p>}
      <dl className="bank-meta">{Object.entries(result.scores).map(([key, score]) => <div key={key}><dt>{dimensions[key]}</dt><dd>{score > 0 ? '+' : ''}{score}</dd></div>)}</dl>
      <p className="small text-body-secondary">Positif: E/S/T/J · Negatif: I/N/F/P · Nol: seimbang.<br />Algoritma: {bank.scoringVersion}. Simulasi ini bukan diagnosis atau validasi psikometrik.</p>
      <div className="actions"><CButton color="primary" onClick={() => { setResult(null); setIndex(0); }}>Tinjau jawaban</CButton><CButton color="secondary" variant="outline" onClick={() => { setAnswers({}); setResult(null); setIndex(0); }}>Ulangi simulasi</CButton></div>
    </CCardBody></CCard> : <CCard><CCardBody>
      <p>Soal {index + 1} dari {bank.questions.length} · {Object.keys(answers).length} terjawab</p>
      <CProgress value={Object.keys(answers).length / bank.questions.length * 100} aria-label="Kemajuan jawaban" className="mb-4" />
      <fieldset><legend className="fs-5">{question.text}</legend>
        {labels.map((label, i) => <CFormCheck className="mb-3" key={`${question.id}-${i}`} type="radio" name={`preview-${question.id}`} id={`preview-${question.id}-${i}`} label={`${i + 1} — ${label}`} checked={answers[question.id] === i + 1} onChange={() => setAnswers((previous) => ({ ...previous, [question.id]: i + 1 }))} />)}
      </fieldset>
      {error && <CAlert color="danger" role="alert">{error}</CAlert>}
      <div className="actions"><CButton color="secondary" variant="outline" disabled={index === 0} onClick={() => setIndex((i) => i - 1)}>Sebelumnya</CButton>
        {index < bank.questions.length - 1 ? <CButton color="primary" disabled={!Object.hasOwn(answers, question.id)} onClick={() => setIndex((i) => i + 1)}>Berikutnya</CButton>
          : <CButton color="primary" disabled={!complete} onClick={calculate}>Hitung hasil simulasi</CButton>}
      </div>
    </CCardBody></CCard>}
  </section>;
}
