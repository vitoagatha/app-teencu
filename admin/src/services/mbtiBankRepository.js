import { collection, doc, documentId, getDocFromServer, getDocsFromServer, limit, orderBy, query, runTransaction, serverTimestamp, startAfter } from 'firebase/firestore';
import { pageFromDocuments, readBank, validateBank } from '../domain/mbtiBank.js';

export function createMbtiBankRepository({ auth, firestore }, uid) {
  const assertSession = () => { if (auth.currentUser?.uid !== uid) throw new Error('Sesi berubah. Silakan masuk kembali.'); };
  return {
    async loadPage(cursor = null) {
      assertSession();
      const constraints = [orderBy('createdAt', 'desc'), orderBy(documentId(), 'desc')];
      if (cursor) constraints.push(startAfter(cursor));
      const result = await getDocsFromServer(query(collection(firestore, 'mbti_tests'), ...constraints, limit(21)));
      assertSession();
      return pageFromDocuments(result.docs);
    },
    async loadActive() {
      assertSession();
      const pointer = await getDocFromServer(doc(firestore, 'mbti_config/active'));
      if (!pointer.exists()) { assertSession(); return null; }
      const id = pointer.data().testId;
      if (typeof id !== 'string' || !/^[a-zA-Z0-9_-]{1,80}$/.test(id)) throw new Error('Pointer aktif tidak valid.');
      const snapshot = await getDocFromServer(doc(firestore, 'mbti_tests', id));
      assertSession();
      if (!snapshot.exists()) throw new Error('Paket aktif tidak ditemukan.');
      const bank = readBank(snapshot);
      if (bank.status !== 'published') throw new Error('Paket aktif belum published.');
      return bank;
    },
    async loadDetail(id) {
      assertSession();
      const snapshot = await getDocFromServer(doc(firestore, 'mbti_tests', id));
      assertSession();
      if (!snapshot.exists()) throw new Error('Paket tidak ditemukan.');
      return readBank(snapshot);
    },
    async copyToDraft(sourceId, newId, title, version) {
      assertSession();
      if (!/^[a-zA-Z0-9_-]{1,80}$/.test(newId)) throw new Error('ID paket tidak valid.');
      const target = doc(firestore, 'mbti_tests', newId);
      await runTransaction(firestore, async (transaction) => {
        assertSession();
        const source = await transaction.get(doc(firestore, 'mbti_tests', sourceId));
        const existing = await transaction.get(target);
        if (!source.exists()) throw new Error('Paket asal tidak ditemukan.');
        if (existing.exists()) throw new Error('ID sudah digunakan. Pilih ID lain atau buka paket tersebut untuk memeriksa hasilnya.');
        const original = readBank(source);
        const data = {
          title: title.trim(), version: version.trim(), scoringVersion: original.scoringVersion,
          questions: original.questions.map(({ id, text, agreeWith }) => ({ id, text, agreeWith })),
          questionIds: original.questions.map(({ id }) => id),
          status: 'draft', createdAt: serverTimestamp(), publishedAt: null,
        };
        validateBank(newId, data);
        transaction.set(target, data);
      });
      assertSession();
    },
  };
}
