import assert from 'node:assert/strict';
import { test } from 'node:test';
import { spawnSync } from 'node:child_process';

const firestoreHost = process.env.FIRESTORE_EMULATOR_HOST;
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
for (const host of [firestoreHost, authHost]) assert.match(host ?? '', /^(127\.0\.0\.1|localhost):\d+$/);
const root = 'projects/demo-teencu/databases/(default)/documents';
const base = `http://${firestoreHost}/v1/${root}`;
async function request(url, token, method = 'GET', body) {
  const response = await fetch(url, { method, headers: {'Content-Type': 'application/json', ...(token ? {Authorization: `Bearer ${token}`} : {})}, body: body ? JSON.stringify(body) : undefined });
  return {status: response.status, data: await response.json()};
}
function value(input) {
  if (input === null) return {nullValue: null};
  if (typeof input === 'string') return {stringValue: input};
  if (typeof input === 'boolean') return {booleanValue: input};
  if (typeof input === 'number') return {integerValue: String(input)};
  if (Array.isArray(input)) return {arrayValue: {values: input.map(value)}};
  return {mapValue: {fields: Object.fromEntries(Object.entries(input).map(([key, v]) => [key, value(v)]))}};
}
const fields = (data) => value(data).mapValue.fields;
async function account(label) {
  const email = `${label}-${Date.now()}@example.test`;
  const result = await request(`http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake`, null, 'POST', {email, password: 'emulator-test-only', returnSecureToken: true});
  assert.equal(result.status, 200, JSON.stringify(result.data));
  return {email, uid: result.data.localId, token: result.data.idToken};
}
const commit = (token, writes) => request(`${base}:commit`, token, 'POST', {writes});
function write(path, data, transforms = [], updateMask) {
  return { update: {name: `${root}/${path}`, fields: fields(data)}, ...(transforms.length ? {updateTransforms: transforms.map((fieldPath) => ({fieldPath, setToServerValue: 'REQUEST_TIME'}))} : {}), ...(updateMask ? {updateMask: {fieldPaths: updateMask}} : {}) };
}
const draft = (version = 'v1') => ({
  title: 'MBTI emulator', version, scoringVersion: 'teencu-centered-v1', status: 'draft', publishedAt: null,
  questionIds: ['a', 'b', 'c', 'd'], questions: [
    {id: 'a', text: 'Energi sosial', agreeWith: 'E'}, {id: 'b', text: 'Detail nyata', agreeWith: 'S'},
    {id: 'c', text: 'Logika', agreeWith: 'T'}, {id: 'd', text: 'Rencana', agreeWith: 'J'},
  ],
});
function resultWrites(uid, id, overrides = {}, profileOverrides = {}) {
  const data = {testId: 'bank-v1', testVersion: 'v1', scoringVersion: 'teencu-centered-v1', answers: {a: 5, b: 5, c: 5, d: 5}, dimensionScores: {ei: 2, sn: 2, tf: 2, jp: 2}, resultType: 'ESTJ', ...overrides};
  return [
    write(`users/${uid}/mbti_results/${id}`, data, ['completedAt']),
    write(`users/${uid}`, {lastMbti: 'ESTJ', lastMbtiResultId: id, ...profileOverrides}, ['lastMbtiDate'], ['lastMbti', 'lastMbtiResultId', ...Object.keys(profileOverrides)]),
  ];
}

test('Versioned bank, publication and private result history', async (t) => {
  const admin = await account('bank-admin');
  const user = await account('bank-user');
  const other = await account('bank-other');
  // Emulator-only trusted setup bypasses rules. Production bootstrap is Console.
  assert.equal((await commit('owner', [write(`content_admins/${admin.uid}`, {enabled: true})])).status, 200);
  assert.equal((await commit(user.token, [write(`users/${user.uid}`, {username: `user-${user.uid}`, points: 0, lastMbti: '', lastMbtiDate: null}, ['createdAt'])])).status, 200);

  await t.test('Users cannot self-promote or create bank content', async () => {
    assert.equal((await commit(user.token, [write(`content_admins/${user.uid}`, {enabled: true})])).status, 403);
    assert.equal((await commit(user.token, [write('mbti_tests/bank-v1', draft(), ['createdAt'])])).status, 403);
  });
  await t.test('Admin can save draft; ordinary users and anonymous cannot read it', async () => {
    const created = await commit(admin.token, [write('mbti_tests/bank-v1', draft(), ['createdAt'])]);
    assert.equal(created.status, 200, JSON.stringify(created.data));
    assert.equal((await request(`${base}/mbti_tests/bank-v1`, admin.token)).status, 200);
    assert.equal((await request(`${base}/mbti_tests/bank-v1`, user.token)).status, 403);
    assert.equal((await request(`${base}/mbti_tests/bank-v1`, null)).status, 403);
    assert.equal((await commit(user.token, [write('mbti_config/active', {testId: 'bank-v1'}, ['updatedAt'])])).status, 403);
    assert.equal((await commit(admin.token, [write('mbti_config/active', {testId: 'bank-v1'}, ['updatedAt'])])).status, 403);
  });
  await t.test('Publish plus activation is atomic; published bank is immutable', async () => {
    const published = await commit(admin.token, [
      write('mbti_tests/bank-v1', {status: 'published'}, ['publishedAt'], ['status']),
      write('mbti_config/active', {testId: 'bank-v1'}, ['updatedAt']),
    ]);
    assert.equal(published.status, 200, JSON.stringify(published.data));
    assert.equal((await request(`${base}/mbti_tests/bank-v1`, user.token)).status, 200);
    assert.equal((await request(`${base}/mbti_tests/bank-v1`, null)).status, 403);
    assert.equal((await commit(admin.token, [write('mbti_tests/bank-v1', {title: 'changed'}, [], ['title'])])).status, 403);
    assert.equal((await request(`${base}/mbti_tests/bank-v1`, admin.token, 'DELETE')).status, 403);
  });
  await t.test('Wrong version, invalid answer values, incomplete answers, ties and mismatched scores fail atomically', async () => {
    for (const overrides of [
      {testVersion: 'v999'}, {scoringVersion: 'fake'}, {testId: 'missing'},
      {answers: {a: 5, b: 5, c: 5}}, {answers: {a: 6, b: 5, c: 5, d: 5}},
      {dimensionScores: {ei: 0, sn: 2, tf: 2, jp: 2}}, {resultType: 'INFP'},
      {points: 100},
    ]) {
      const response = await commit(user.token, resultWrites(user.uid, 'invalid', overrides));
      assert.equal(response.status, 403, JSON.stringify(response.data));
    }
    assert.equal((await request(`${base}/users/${user.uid}/mbti_results/invalid`, user.token)).status, 404);
  });
  await t.test('Standalone result, standalone pointer and rewards are denied', async () => {
    const writes = resultWrites(user.uid, 'one');
    assert.equal((await commit(user.token, [writes[0]])).status, 403);
    assert.equal((await commit(user.token, [writes[1]])).status, 403);
    assert.equal((await commit(user.token, resultWrites(user.uid, 'one', {}, {points: 50}))).status, 403);
  });
  await t.test('Owner stores result and profile together; history is private and immutable', async () => {
    const response = await commit(user.token, resultWrites(user.uid, 'one'));
    assert.equal(response.status, 200, JSON.stringify(response.data));
    const url = `${base}/users/${user.uid}/mbti_results/one`;
    assert.equal((await request(url, user.token)).status, 200);
    assert.equal((await request(url, other.token)).status, 403);
    assert.equal((await request(url, admin.token)).status, 403);
    assert.equal((await request(url, null)).status, 403);
    assert.equal((await commit(user.token, resultWrites(user.uid, 'one'))).status, 403);
    assert.equal((await request(url, user.token, 'DELETE')).status, 403);
    const profile = await request(`${base}/users/${user.uid}`, user.token);
    assert.equal(profile.data.fields.points.integerValue, '0');
    assert.equal(profile.data.fields.lastMbtiResultId.stringValue, 'one');
    const query = {structuredQuery: {from: [{collectionId: 'mbti_results'}], orderBy: [{field: {fieldPath: 'completedAt'}, direction: 'DESCENDING'}], limit: 21}};
    assert.equal((await request(`${base}/users/${user.uid}:runQuery`, user.token, 'POST', query)).status, 200);
    assert.equal((await request(`${base}/users/${user.uid}:runQuery`, other.token, 'POST', query)).status, 403);
    query.structuredQuery.limit = 22;
    assert.equal((await request(`${base}/users/${user.uid}:runQuery`, user.token, 'POST', query)).status, 403);
  });
  await t.test('Old published version remains usable after active version changes', async () => {
    assert.equal((await commit(admin.token, [write('mbti_tests/bank-v2', draft('v2'), ['createdAt'])])).status, 200);
    assert.equal((await commit(admin.token, [write('mbti_tests/bank-v2', {status: 'published'}, ['publishedAt'], ['status']), write('mbti_config/active', {testId: 'bank-v2'}, ['updatedAt'])])).status, 200);
    assert.equal((await commit(user.token, resultWrites(user.uid, 'two'))).status, 200);
    assert.equal((await request(`${base}/mbti_tests/bank-v1`, user.token)).status, 200);
    assert.equal((await commit(other.token, resultWrites(user.uid, 'intrusion'))).status, 403);
  });
  await t.test('PowerShell publisher supports draft, publish/activate, immutability and selecting old version', () => {
    const credential = `$credential = [System.Management.Automation.PSCredential]::new('${admin.email}', (ConvertTo-SecureString 'emulator-test-only' -AsPlainText -Force))`;
    for (const action of ['Draft', 'Publish', 'Activate']) {
      const command = `${credential}; & ./tools/Publish-MbtiBank.ps1 -Action ${action} -TestId cli-v1 -UseEmulator -ProjectId demo-teencu -Credential $credential ${action === 'Publish' ? '-Activate' : ''}`;
      const publisherRun = spawnSync('powershell.exe', ['-NoProfile', '-Command', command], {encoding: 'utf8', timeout: 30000, env: Object.fromEntries(Object.entries(process.env).filter(([key]) => key.toUpperCase() !== 'PSMODULEPATH'))});
      assert.equal(publisherRun.status, 0, publisherRun.stdout + publisherRun.stderr);
    }
    const duplicate = spawnSync('powershell.exe', ['-NoProfile', '-Command', `${credential}; & ./tools/Publish-MbtiBank.ps1 -Action Publish -TestId cli-v1 -UseEmulator -ProjectId demo-teencu -Credential $credential`], {encoding: 'utf8', timeout: 30000, env: Object.fromEntries(Object.entries(process.env).filter(([key]) => key.toUpperCase() !== 'PSMODULEPATH'))});
    assert.notEqual(duplicate.status, 0);
  });
});
