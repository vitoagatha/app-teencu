export function validateBank(id, data) {
  const pattern = /^[a-zA-Z0-9_-]{1,80}$/;
  if (typeof id !== 'string' || !pattern.test(id)) throw new Error('ID paket harus 1–80 huruf, angka, tanda - atau _.');
  if (typeof data.title !== 'string' || !data.title.trim() || data.title.length > 160) throw new Error('Judul wajib diisi, maksimal 160 karakter.');
  if (typeof data.version !== 'string' || !data.version.trim() || data.version.length > 80) throw new Error('Versi wajib diisi, maksimal 80 karakter.');
  if (data.scoringVersion !== 'teencu-centered-v1') throw new Error('Algoritma belum didukung.');
  if (!Array.isArray(data.questions) || data.questions.length < 4 || data.questions.length > 80) throw new Error('Paket harus berisi 4–80 soal.');
  const ids = new Set();
  const dimensions = new Set();
  const mapping = { E: 'ei', I: 'ei', S: 'sn', N: 'sn', T: 'tf', F: 'tf', J: 'jp', P: 'jp' };
  for (const q of data.questions) {
    if (!q || typeof q.id !== 'string' || !pattern.test(q.id) || ids.has(q.id)) throw new Error('ID soal tidak valid atau duplikat.');
    if (typeof q.text !== 'string' || !q.text.trim() || q.text.length > 1000) throw new Error('Teks soal wajib diisi, maksimal 1.000 karakter.');
    if (!Object.hasOwn(mapping, q.agreeWith)) throw new Error('Arah penilaian tidak valid.');
    ids.add(q.id); dimensions.add(mapping[q.agreeWith]);
  }
  if (dimensions.size !== 4) throw new Error('Keempat dimensi harus terwakili.');
  if (!Array.isArray(data.questionIds) || data.questionIds.length !== data.questions.length || data.questionIds.some((id, i) => id !== data.questions[i].id)) throw new Error('Urutan ID soal tidak cocok.');
}
export function readBank(snapshot) {
  const data = snapshot.data();
  validateBank(snapshot.id, data);
  if (!['draft', 'published'].includes(data.status)) throw new Error('Status tidak valid.');
  return { ...data, id: snapshot.id };
}
export function pageFromDocuments(documents) {
  const visible = documents.slice(0, 20);
  return {
    entries: visible.map((doc) => { try { return readBank(doc); } catch { return { id: doc.id, invalid: true }; } }),
    hasMore: documents.length > 20,
    cursor: visible.at(-1) ?? null,
  };
}
