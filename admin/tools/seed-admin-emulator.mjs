// Local test fixtures only. All endpoints and project IDs are intentionally fixed.
const authUrl = 'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1';
const firestoreUrl = 'http://127.0.0.1:8080/v1/projects/demo-teencu/databases/(default)/documents';
const password = 'Teencu-local-only-123';
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
  console.log(`Password khusus emulator untuk kedua akun: ${password}`);
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
}
