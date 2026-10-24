import assert from 'node:assert/strict';
import { test } from 'node:test';

// Deliberately refuse any non-local target; these tests never touch cloud data.
const firestoreHost = process.env.FIRESTORE_EMULATOR_HOST;
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
for (const host of [firestoreHost, authHost]) {
  assert.match(host ?? '', /^(127\.0\.0\.1|localhost):\d+$/);
}
const project = 'demo-teencu';
const root = `projects/${project}/databases/(default)/documents`;
const databaseUrl = `http://${firestoreHost}/v1/${root}`;

async function request(url, token, method = 'GET', body) {
  const response = await fetch(url, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  return { status: response.status, data: await response.json() };
}
async function account(label) {
  const result = await request(
    `http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key`,
    null, 'POST', {
      email: `${label}-${Date.now()}@example.test`,
      password: 'test-only-password',
      returnSecureToken: true,
    },
  );
  assert.equal(result.status, 200, JSON.stringify(result.data));
  return { uid: result.data.localId, token: result.data.idToken };
}
function createWrite(uid, overrides = {}) {
  return {
    update: {
      name: `${root}/users/${uid}`,
      fields: {
        username: { stringValue: `user-${uid}` },
        points: { integerValue: '0' },
        lastMbti: { stringValue: '' },
        lastMbtiDate: { nullValue: null },
        ...overrides,
      },
    },
    currentDocument: { exists: false },
    updateTransforms: [{ fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME' }],
  };
}
async function commit(token, write) {
  return request(`${databaseUrl}:commit`, token, 'POST', { writes: [write] });
}
function updateWrite(uid, fields, timestamp = false) {
  return {
    update: { name: `${root}/users/${uid}`, fields },
    updateMask: { fieldPaths: Object.keys(fields) },
    ...(timestamp ? { updateTransforms: [{ fieldPath: 'lastMbtiDate', setToServerValue: 'REQUEST_TIME' }] } : {}),
  };
}

test('Private profiles and protected fields', async (t) => {
  const owner = await account('owner');
  const other = await account('other');
  const ownerUrl = `${databaseUrl}/users/${owner.uid}`;

  await t.test('Anonymous access and creating another account profile are denied', async () => {
    assert.equal((await commit(null, createWrite(owner.uid))).status, 403);
    assert.equal((await commit(other.token, createWrite(owner.uid))).status, 403);
    assert.equal((await request(ownerUrl, null)).status, 403);
  });
  await t.test('Initial rewards and admin roles cannot be supplied by client', async () => {
    assert.equal((await commit(owner.token, createWrite(owner.uid, { points: { integerValue: '100' } }))).status, 403);
    assert.equal((await commit(owner.token, createWrite(owner.uid, { role: { stringValue: 'admin' } }))).status, 403);
  });
  await t.test('Owner can check for a missing profile then create and read it', async () => {
    assert.equal((await request(ownerUrl, owner.token)).status, 404);
    const result = await commit(owner.token, createWrite(owner.uid));
    assert.equal(result.status, 200, JSON.stringify(result.data));
    assert.equal((await request(ownerUrl, owner.token)).status, 200);
  });
  await t.test('Other users cannot read profile or list all users', async () => {
    assert.equal((await request(ownerUrl, other.token)).status, 403);
    assert.equal((await request(`${databaseUrl}/users`, owner.token)).status, 403);
  });
  await t.test('Owner cannot increase points, grant role, change creation date, or delete profile', async () => {
    for (const fields of [
      { points: { integerValue: '100' } },
      { role: { stringValue: 'admin' } },
      { createdAt: { timestampValue: '2000-01-01T00:00:00Z' } },
    ]) {
      assert.equal((await commit(owner.token, updateWrite(owner.uid, fields))).status, 403);
    }
    assert.equal((await request(ownerUrl, owner.token, 'DELETE')).status, 403);
  });
  await t.test('Legacy profile-only result updates are rejected without atomic history', async () => {
    assert.equal((await commit(owner.token, updateWrite(owner.uid, { lastMbti: { stringValue: 'INVALID' } }, true))).status, 403);
    assert.equal((await commit(owner.token, updateWrite(owner.uid, { lastMbti: { stringValue: 'INFP' } }))).status, 403);
    const result = await commit(owner.token, updateWrite(owner.uid, { lastMbti: { stringValue: 'INFP' } }, true));
    assert.equal(result.status, 403, JSON.stringify(result.data));
    const profile = await request(ownerUrl, owner.token);
    assert.equal(profile.data.fields.points.integerValue, '0');
    assert.equal(profile.data.fields.lastMbti.stringValue, '');
    assert.equal((await commit(other.token, updateWrite(owner.uid, { lastMbti: { stringValue: 'ENTJ' } }, true))).status, 403);
  });
  await t.test('Chat and reward collections remain closed', async () => {
    for (const collection of ['chats', 'chat_rooms', 'point_transactions']) {
      assert.equal((await request(`${databaseUrl}/${collection}/test`, owner.token)).status, 403);
      const result = await commit(owner.token, {
        update: { name: `${root}/${collection}/test`, fields: { value: { stringValue: 'test' } } },
      });
      assert.equal(result.status, 403);
    }
  });
});
