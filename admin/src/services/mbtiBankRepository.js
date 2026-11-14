import { collection, doc, documentId, getDocFromServer, getDocsFromServer, limit, orderBy, query, runTransaction, serverTimestamp, startAfter } from 'firebase/firestore';
import { pageFromDocuments, readBank, validateBank } from '../domain/mbtiBank.js';
import { fingerprint, validateDraft } from '../domain/mbtiDraft.js';

export function createMbtiBankRepository({ auth, firestore }, uid) {
  const assertSession = () => { if (auth.currentUser?.uid !== uid) throw new Error('Sesi berubah. Silakan masuk kembali.'); };
  return {
    async publish(bank) {
      assertSession();
      validateBank(bank.id, bank);
      const expected = fingerprint(bank);
      await runTransaction(firestore, async (transaction) => {
        assertSession();
        const reference = doc(firestore, 'mbti_tests', bank.id);
        const snapshot = await transaction.get(reference);
        if (!snapshot.exists()) throw new Error('Draft tidak ditemukan. Muat ulang paket.');
        const current = readBank(snapshot);
        if (current.status !== 'draft') throw new Error('Paket sudah published. Muat ulang untuk memeriksa statusnya.');
        if (fingerprint(current) !== expected) throw new Error('Draft berubah sejak ditinjau. Muat ulang dan periksa kembali sebelum publish.');
        transaction.update(reference, { status: 'published', publishedAt: serverTimestamp() });
      });
      assertSession();
    },
    async prepareActivation(id) {
      assertSession();
      return runTransaction(firestore, async (transaction) => {
        assertSession();
        const snapshot = await transaction.get(doc(firestore, 'mbti_tests', id));
        const active = await transaction.get(doc(firestore, 'mbti_config/active'));
        if (!snapshot.exists()) throw new Error('Paket tujuan tidak ditemukan.');
        const target = readBank(snapshot);
        if (target.status !== 'published') throw new Error('Hanya paket published yang dapat diaktifkan.');
        const pointer = active.exists() ? active.data() : null;
        let current = null;
        if (pointer && typeof pointer.testId === 'string' && /^[a-zA-Z0-9_-]{1,80}$/.test(pointer.testId)) {
          const currentSnapshot = await transaction.get(doc(firestore, 'mbti_tests', pointer.testId));
          if (currentSnapshot.exists()) current = readBank(currentSnapshot);
        }
        assertSession();
        return { target, pointer, current };
      });
    },
    async activate(context) {
      assertSession();
      // Freeze confirmation evidence before asynchronous retries (including ABA
      // changes to active testId: updatedAt must still match).
      const targetId = context.target.id;
      const expectedTarget = fingerprint(context.target);
      const expectedPointer = fingerprint(context.pointer);
      await runTransaction(firestore, async (transaction) => {
        assertSession();
        const snapshot = await transaction.get(doc(firestore, 'mbti_tests', targetId));
        const reference = doc(firestore, 'mbti_config/active');
        const active = await transaction.get(reference);
        if (!snapshot.exists()) throw new Error('Paket tujuan tidak ditemukan.');
        const target = readBank(snapshot);
        if (target.status !== 'published') throw new Error('Paket tujuan belum published.');
        if (fingerprint(target) !== expectedTarget) throw new Error('Paket tujuan berubah. Tinjau ulang sebelum aktivasi.');
        const currentPointer = active.exists() ? active.data() : null;
        if (fingerprint(currentPointer) !== expectedPointer) throw new Error('Versi aktif berubah oleh admin lain. Tinjau ulang dan konfirmasi kembali.');
        if (currentPointer?.testId === targetId) return;
        transaction.set(reference, { testId: targetId, updatedAt: serverTimestamp() });
      });
      assertSession();
    },
    async saveDraft(id, bank, baseline = null) {
      assertSession();
      // Copy inputs before the async transaction; retries must use the same edit.
      const content = validateDraft(id, bank);
      const expected = baseline ? fingerprint(baseline) : null;
      const reference = doc(firestore, 'mbti_tests', id);
      const saved = await runTransaction(firestore, async (transaction) => {
        assertSession();
        const snapshot = await transaction.get(reference);
        if (!baseline) {
          if (snapshot.exists()) throw new Error('ID paket sudah digunakan. Pilih ID lain.');
          transaction.set(reference, { ...content, status: 'draft', createdAt: serverTimestamp(), publishedAt: null });
          return null;
        }
        if (!snapshot.exists()) throw new Error('Draft tidak ditemukan. Muat ulang data.');
        const current = readBank(snapshot);
        if (current.status !== 'draft') throw new Error('Paket sudah published dan tidak dapat diedit.');
        if (fingerprint(current) !== expected) throw new Error('Draft sudah berubah di tab/admin lain. Muat ulang sebelum menyimpan.');
        transaction.update(reference, content);
        return { ...current, ...content };
      });
      assertSession();
      return saved;
    },
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
