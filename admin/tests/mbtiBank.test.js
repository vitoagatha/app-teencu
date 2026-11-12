import assert from 'node:assert/strict';
import { test } from 'node:test';
import { readFileSync } from 'node:fs';
import { pageFromDocuments, validateBank } from '../src/domain/mbtiBank.js';

const seed = JSON.parse(readFileSync(new URL('../../seed/mbti-v1.json', import.meta.url)));
const bank = () => ({ ...structuredClone(seed), questionIds: seed.questions.map((q) => q.id), status: 'published' });
test('Seed contract is accepted for admin and copying', () => validateBank('mbti-v1', bank()));
test('Invalid content is rejected before copying', () => {
  for (const mutate of [
    (b) => { b.title = ' '; }, (b) => { b.version = ''; },
    (b) => { b.scoringVersion = 'future'; }, (b) => { b.questions[0].agreeWith = 'X'; },
    (b) => { b.questions[0].text = ''; }, (b) => { b.questions[1].id = b.questions[0].id; },
    (b) => { b.questions = b.questions.slice(0, 4); b.questionIds = b.questions.map((q) => q.id); },
    (b) => { b.questionIds.reverse(); },
  ]) { const data = bank(); mutate(data); assert.throws(() => validateBank('copy', data)); }
  assert.throws(() => validateBank('bad/id', bank()));
  assert.throws(() => validateBank(undefined, bank()));
});
test('Pagination displays 20 and uses last displayed document, not lookahead', () => {
  const documents = Array.from({ length: 21 }, (_, i) => ({ id: `bank-${i}`, data: bank }));
  const page = pageFromDocuments(documents);
  assert.equal(page.entries.length, 20);
  assert.equal(page.cursor, documents[19]);
  assert.equal(page.hasMore, true);
  assert.equal(pageFromDocuments(documents.slice(0, 20)).hasMore, false);
  assert.equal(pageFromDocuments([]).cursor, null);
});
test('One corrupt document does not hide the entire list', () => {
  const page = pageFromDocuments([{ id: 'bad', data: () => ({}) }, { id: 'good', data: bank }]);
  assert.equal(page.entries[0].invalid, true);
  assert.equal(page.entries[1].questions.length, 20);
});
