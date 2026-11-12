// Local test fixtures only. All endpoints and project IDs are intentionally fixed.
import { readFile } from 'node:fs/promises';
const authUrl = 'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1';
const firestoreUrl = 'http://127.0.0.1:8080/v1/projects/demo-teencu/databases/(default)/documents';
const password = 'Teencu-local-only-123';
function field(value) {
  if (value === null) return { nullValue: null };
  if (typeof value === 'string') return { stringValue: value };
  if (Array.isArray(value)) return { arrayValue: { values: value.map(field) } };
  return { mapValue: { fields: Object.fromEntries(Object.entries(value).map(([key, item]) => [key, field(item)])) } };
}
async function createIfMissing(path, fields) {
  const headers = { 'Content-Type': 'application/json', Authorization: 'Bearer owner' };
  const existing = await fetch(`${firestoreUrl}/${path}`, { headers });
  if (existing.ok) return;
  if (existing.status !== 404) throw new Error(`Gagal memeriksa data contoh: ${path}.`);
  const response = await fetch(`${firestoreUrl}/${path}?currentDocument.exists=false`, {
    method: 'PATCH', headers,
    body: JSON.stringify({ fields }),
  });
  if (!response.ok) {
    const concurrent = await fetch(`${firestoreUrl}/${path}`, { headers });
    if (!concurrent.ok) throw new Error(`Gagal menyiapkan data contoh: ${path}.`);
  }
}
async function seedBanks() {
  const seed = JSON.parse(await readFile(new URL('../../seed/mbti-v1.json', import.meta.url), 'utf8'));
  const timestamp = { timestampValue: new Date().toISOString() };
  for (const [id, status, version] of [['demo-mbti-v1', 'published', 'v1'], ['demo-mbti-v2-draft', 'draft', 'v2']]) {
    const data = { ...seed, version, status, questionIds: seed.questions.map((q) => q.id), publishedAt: null };
    const fields = field(data).mapValue.fields;
    fields.createdAt = timestamp;
    if (status === 'published') fields.publishedAt = timestamp;
    await createIfMissing(`mbti_tests/${id}`, fields);
  }
  await createIfMissing('mbti_config/active', { testId: { stringValue: 'demo-mbti-v1' }, updatedAt: timestamp });
  console.log('Paket contoh published/draft tersedia. Paket dan pointer yang sudah ada tidak ditimpa.');
}
async function account(email, admin) {
  const body = JSON.stringify({ email, password, returnSecureToken: true });
  let response = await fetch(`${authUrl}/accounts:signUp?key=demo-key`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body,
  });
  let result = await response.json();
  if (!response.ok && result.error?.message === 'EMAIL_EXISTS') {
    response = await fetch(`${authUrl}/accounts:signInWithPassword?key=demo-key`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' }, body,
    });
    result = await response.json();
  }
  if (!response.ok) throw new Error('Gagal menyiapkan akun lokal. Periksa emulator Auth.');
  const role = await fetch(`${firestoreUrl}/content_admins/${result.localId}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json', Authorization: 'Bearer owner' },
    body: JSON.stringify({ fields: { enabled: { booleanValue: admin } } }),
  });
  if (!role.ok) throw new Error('Gagal menyiapkan izin lokal. Periksa emulator Firestore.');
  console.log(`${email}: ${admin ? 'admin aktif' : 'akun biasa, akses ditolak'} (UID: ${result.localId})`);
}
try {
  await account('admin@teencu.example', true);
  await account('user@teencu.example', false);
  await seedBanks();
  console.log(`Password khusus emulator untuk kedua akun: ${password}`);
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
}
