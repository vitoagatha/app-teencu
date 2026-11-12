import assert from 'node:assert/strict';
import { test } from 'node:test';
import { resolveFirebaseConfig } from '../src/lib/firebaseConfig.js';

const cloud = {
  VITE_FIREBASE_TARGET: 'cloud',
  VITE_FIREBASE_API_KEY: 'test-key',
  VITE_FIREBASE_AUTH_DOMAIN: 'teencu-dev.firebaseapp.com',
  VITE_FIREBASE_PROJECT_ID: 'teencu-dev',
  VITE_FIREBASE_APP_ID: '1:123:web:abc123',
};
test('Default uses demo project even if cloud values are present', () => {
  const { VITE_FIREBASE_TARGET, ...values } = cloud;
  assert.equal(resolveFirebaseConfig(values).config.projectId, 'demo-teencu');
});
test('Explicit valid cloud config is accepted', () => {
  assert.equal(resolveFirebaseConfig(cloud).target, 'cloud');
});
test('Invalid target never falls back to cloud', () => {
  assert.throws(() => resolveFirebaseConfig({ ...cloud, VITE_FIREBASE_TARGET: 'typo' }));
});
test('Cloud rejects missing config, wrong project and Android app id', () => {
  for (const override of [
    { VITE_FIREBASE_API_KEY: '' },
    { VITE_FIREBASE_PROJECT_ID: 'another-project' },
    { VITE_FIREBASE_APP_ID: '1:123:android:abc123' },
  ]) assert.throws(() => resolveFirebaseConfig({ ...cloud, ...override }));
});
