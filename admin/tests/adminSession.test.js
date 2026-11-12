import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createAdminSession } from '../src/auth/adminSession.js';
import { loginErrorMessage } from '../src/services/adminAccess.js';

function fixture(t, options) {
  const auths = [];
  const roles = [];
  const access = {
    watchSession(next, error) { const sub = { next, error }; auths.push(sub); return () => { sub.stopped = true; }; },
    watchAccess(uid, next, error) { const sub = { uid, next, error }; roles.push(sub); return () => { sub.stopped = true; }; },
    async logout() { auths.at(-1).next(null); },
  };
  const controller = createAdminSession(access, options);
  controller.start();
  t.after(() => controller.stop());
  return { controller, access, auths, roles, status: () => controller.getSnapshot().status };
}
const user = { uid: 'admin-a', email: 'admin@example.test' };

test('Restored session needs server permission; cached grant never authorizes', (t) => {
  const f = fixture(t);
  f.auths[0].next(user);
  assert.equal(f.status(), 'checking');
  f.roles[0].next({ enabled: true, confirmed: false });
  assert.equal(f.status(), 'checking');
  f.roles[0].next({ enabled: true, confirmed: true });
  assert.equal(f.status(), 'authorized');
  f.roles[0].next({ enabled: false, confirmed: true });
  assert.equal(f.status(), 'denied');
});
test('Missing/disabled role denies access; an enabled role can restore it', (t) => {
  const f = fixture(t);
  f.auths[0].next(user);
  f.roles[0].next({ enabled: false, confirmed: true });
  assert.equal(f.status(), 'denied');
  f.roles[0].next({ enabled: true, confirmed: true });
  assert.equal(f.status(), 'authorized');
});
test('Account switch cancels previous listener and ignores late permission', (t) => {
  const f = fixture(t);
  f.auths[0].next(user);
  f.roles[0].next({ enabled: true, confirmed: true });
  f.auths[0].next({ uid: 'regular-user' });
  assert.equal(f.roles[0].stopped, true);
  assert.equal(f.status(), 'checking');
  f.roles[0].next({ enabled: true, confirmed: true });
  assert.equal(f.status(), 'checking');
  f.roles[1].next({ enabled: false, confirmed: true });
  assert.equal(f.status(), 'denied');
});
test('Permission failure removes access and retry starts a fresh check', (t) => {
  const f = fixture(t);
  f.auths[0].next(user);
  f.roles[0].next({ enabled: true, confirmed: true });
  f.roles[0].error(new Error('offline'));
  assert.equal(f.status(), 'access-error');
  f.controller.retry();
  assert.equal(f.status(), 'checking');
  f.roles[0].next({ enabled: true, confirmed: true });
  assert.equal(f.status(), 'checking');
  f.roles[1].next({ enabled: true, confirmed: true });
  assert.equal(f.status(), 'authorized');
});
test('Logout clears private state; late callbacks cannot reopen dashboard', async (t) => {
  const f = fixture(t);
  f.auths[0].next(user);
  f.roles[0].next({ enabled: true, confirmed: true });
  await f.controller.logout();
  assert.equal(f.status(), 'signed-out');
  assert.equal(f.controller.getSnapshot().user, null);
  f.roles[0].next({ enabled: true, confirmed: true });
  assert.equal(f.status(), 'signed-out');
});
test('Failed logout keeps dashboard locked', async (t) => {
  const f = fixture(t);
  f.auths[0].next(user);
  f.roles[0].next({ enabled: true, confirmed: true });
  f.access.logout = async () => { throw new Error('failed'); };
  await f.controller.logout();
  assert.equal(f.status(), 'logout-error');
});
test('Stop/start lifecycle ignores callbacks from old auth subscription', (t) => {
  const f = fixture(t);
  f.controller.stop();
  f.controller.start();
  f.auths[0].next(user);
  assert.equal(f.status(), 'restoring');
  f.auths[1].next(null);
  assert.equal(f.status(), 'signed-out');
});
test('Unconfirmed role times out instead of hanging or authorizing', async (t) => {
  const f = fixture(t, { timeoutMs: 10 });
  f.auths[0].next(user);
  await new Promise((resolve) => setTimeout(resolve, 25));
  assert.equal(f.status(), 'access-error');
});
test('Account discovery errors share one generic login message', () => {
  assert.equal(loginErrorMessage({ code: 'auth/user-not-found' }), loginErrorMessage({ code: 'auth/wrong-password' }));
});
