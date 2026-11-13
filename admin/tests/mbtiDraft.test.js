import { test } from 'node:test';
import assert from 'node:assert/strict';
import { draftContent, fingerprint, moveQuestion, validateDraft } from '../src/domain/mbtiDraft.js';
const bank = () => ({ title: 'Draft', version: 'v2', questions: ['E', 'S', 'T', 'J'].map((agreeWith, i) => ({ id: `q${i}`, text: `Soal ${i}`, agreeWith })) });
test('Saving derives ordered IDs and snapshots independent question objects', () => {
  const original = bank();
  const content = validateDraft('draft-1', original);
  original.questions[0].text = 'changed later';
  assert.equal(content.questions[0].text, 'Soal 0');
  assert.deepEqual(content.questionIds, ['q0', 'q1', 'q2', 'q3']);
});
test('Reordering preserves IDs and direction; bounds do not alter the list', () => {
  const original = bank().questions;
  const moved = moveQuestion(original, 0, 1);
  assert.equal(moved[1], original[0]);
  assert.equal(original[0].id, 'q0');
  assert.deepEqual(draftContent({ ...bank(), questions: moved }).questionIds, ['q1', 'q0', 'q2', 'q3']);
  assert.equal(moveQuestion(original, 0, -1), original);
});
test('Fingerprint ignores object key ordering, but detects edit and array order', () => {
  assert.equal(fingerprint({ a: 1, b: 2 }), fingerprint({ b: 2, a: 1 }));
  const original = bank();
  assert.notEqual(fingerprint(original), fingerprint({ ...original, title: 'Another title' }));
  assert.notEqual(fingerprint(original), fingerprint({ ...original, questions: [...original.questions].reverse() }));
});
test('Removing a required dimension, adding empty text or duplicate IDs blocks save', () => {
  const removed = bank(); removed.questions.pop();
  assert.throws(() => validateDraft('draft', removed));
  const empty = bank(); empty.questions.push({ id: 'new', text: '', agreeWith: 'I' });
  assert.throws(() => validateDraft('draft', empty));
  const duplicate = bank(); duplicate.questions.push({ ...duplicate.questions[0] });
  assert.throws(() => validateDraft('draft', duplicate));
});
