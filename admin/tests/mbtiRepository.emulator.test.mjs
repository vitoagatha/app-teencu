import assert from 'node:assert/strict';
import { test } from 'node:test';
import { initializeApp, deleteApp } from 'firebase/app';
import { getAuth, connectAuthEmulator, createUserWithEmailAndPassword } from 'firebase/auth';
import { getFirestore, connectFirestoreEmulator, collection, query, limit, getDocsFromServer, doc, getDocFromServer, terminate } from 'firebase/firestore';
import { createMbtiBankRepository } from '../src/services/mbtiBankRepository.js';
for (const host of [process.env.FIRESTORE_EMULATOR_HOST, process.env.FIREBASE_AUTH_EMULATOR_HOST]) assert.match(host ?? '', /^(127\.0\.0\.1|localhost):\d+$/);
const projectId = 'demo-teencu';
const base = `http://${process.env.FIRESTORE_EMULATOR_HOST}/v1/projects/${projectId}/databases/(default)/documents`;
async function ownerWrite(path, data) {
  const response = await fetch(`${base}/${path}`, { method: 'PATCH', headers: { Authorization: 'Bearer owner', 'Content-Type': 'application/json' }, body: JSON.stringify({ fields: data }) });
  assert.equal(response.status, 200, await response.text());
}
const str = (stringValue) => ({ stringValue });
const questions = ['E', 'S', 'T', 'J'].map((agreeWith, i) => ({ mapValue: { fields: { id: str(`q${i}`), text: str(`Question ${i}`), agreeWith: str(agreeWith) } } }));

test('Admin repository: bounded query, cursor, active version, copying and revocation', { timeout: 60000 }, async () => {
  const app = initializeApp({ apiKey: 'fake', projectId }, `bank-test-${Date.now()}`);
  const auth = getAuth(app);
  connectAuthEmulator(auth, `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}`, { disableWarnings: true });
  const firestore = getFirestore(app);
  const [host, port] = process.env.FIRESTORE_EMULATOR_HOST.split(':');
  connectFirestoreEmulator(firestore, host, Number(port));
  try {
    const { user } = await createUserWithEmailAndPassword(auth, `dashboard-${Date.now()}@example.test`, 'emulator-test-only');
    const repository = createMbtiBankRepository({ auth, firestore }, user.uid);
    await assert.rejects(repository.loadPage(), (e) => e.code === 'permission-denied');
    await ownerWrite(`content_admins/${user.uid}`, { enabled: { booleanValue: true } });
    const prefix = `dashboard-${Date.now()}`;
    await Promise.all(Array.from({ length: 23 }, (_, i) => ownerWrite(`mbti_tests/${prefix}-${i}`, {
      title: str(`Bank ${i}`), version: str('v1'), scoringVersion: str('teencu-centered-v1'),
      status: str(i === 0 ? 'published' : 'draft'),
      createdAt: { timestampValue: '2099-01-01T00:00:00Z' },
      publishedAt: i === 0 ? { timestampValue: '2099-01-01T00:00:00Z' } : { nullValue: null },
      questions: { arrayValue: { values: questions } },
      questionIds: { arrayValue: { values: [0, 1, 2, 3].map((i) => str(`q${i}`)) } },
    })));
    await ownerWrite('mbti_config/active', { testId: str(`${prefix}-0`), updatedAt: { timestampValue: '2099-01-01T00:00:00Z' } });
    const first = await repository.loadPage();
    const second = await repository.loadPage(first.cursor);
    assert.equal(first.entries.length, 20); assert.equal(first.hasMore, true);
    assert.equal(new Set([...first.entries, ...second.entries].map((b) => b.id)).size, first.entries.length + second.entries.length);
    assert.equal((await repository.loadActive()).id, `${prefix}-0`);
    assert.equal((await repository.loadDetail(`${prefix}-1`)).status, 'draft');
    await assert.rejects(getDocsFromServer(collection(firestore, 'mbti_tests')), (e) => e.code === 'permission-denied');
    await assert.rejects(getDocsFromServer(query(collection(firestore, 'mbti_tests'), limit(22))), (e) => e.code === 'permission-denied');
    await repository.copyToDraft(`${prefix}-0`, `${prefix}-copy`, 'Copied bank', 'v2');
    const copied = await repository.loadDetail(`${prefix}-copy`);
    assert.equal(copied.status, 'draft'); assert.equal(copied.publishedAt, null);
    assert.equal(copied.questions.length, 4); assert.equal(copied.version, 'v2');
    assert.ok(copied.createdAt.toDate());
    await assert.rejects(repository.copyToDraft(`${prefix}-0`, `${prefix}-copy`, 'Overwrite', 'v3'));
    assert.equal((await repository.loadDetail(`${prefix}-copy`)).title, 'Copied bank');
    assert.equal((await repository.loadDetail(`${prefix}-0`)).status, 'published');
    const baseline = await repository.loadDetail(`${prefix}-copy`);
    const edited = { ...baseline, title: 'Edited title', questions: [...baseline.questions].reverse() };
    const saved = await repository.saveDraft(baseline.id, edited, baseline);
    assert.equal(saved.title, 'Edited title');
    const reloaded = await repository.loadDetail(baseline.id);
    assert.deepEqual(reloaded.questionIds, ['q3', 'q2', 'q1', 'q0']);
    assert.equal(reloaded.createdAt.toMillis(), baseline.createdAt.toMillis());
    await assert.rejects(repository.saveDraft(baseline.id, { ...baseline, title: 'Stale overwrite' }, baseline), /sudah berubah/);
    const published = await repository.loadDetail(`${prefix}-0`);
    await assert.rejects(repository.saveDraft(published.id, { ...published, title: 'Forbidden' }, published), /published/);
    await repository.saveDraft(`${prefix}-new`, { ...baseline, title: 'New draft' });
    assert.equal((await repository.loadDetail(`${prefix}-new`)).status, 'draft');
    await assert.rejects(repository.saveDraft(`${prefix}-new`, baseline), /sudah digunakan/);
    await assert.rejects(repository.saveDraft(`${prefix}-invalid`, { ...baseline, questions: [] }));
    await ownerWrite(`content_admins/${user.uid}`, { enabled: { booleanValue: false } });
    await assert.rejects(repository.loadPage(), (e) => e.code === 'permission-denied');
    await assert.rejects(repository.loadDetail(`${prefix}-1`), (e) => e.code === 'permission-denied');
    await assert.rejects(repository.copyToDraft(`${prefix}-0`, `${prefix}-blocked`, 'Denied', 'v9'));
    await assert.rejects(repository.saveDraft(baseline.id, { ...reloaded, title: 'Revoked' }, reloaded));
    assert.equal((await getDocFromServer(doc(firestore, 'mbti_tests', `${prefix}-0`))).exists(), true);
  } finally { await terminate(firestore); await deleteApp(app); }
});
