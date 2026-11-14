import assert from 'node:assert/strict';
import { test } from 'node:test';
import { readFileSync } from 'node:fs';
import { calculateMbti, createPreview, mbtiScoringVersion } from '../src/domain/mbtiScoring.js';
const fixture = JSON.parse(readFileSync(new URL('../../test/fixtures/mbti-scoring-cases.json', import.meta.url)));
assert.equal(fixture.scoringVersion, mbtiScoringVersion);
for (const scenario of fixture.cases) {
  test(`Shared Dart/JS scoring: ${scenario.name}`, () => {
    assert.deepEqual(calculateMbti({ questions: fixture.banks[scenario.bank], answers: scenario.answers }), scenario.expected);
  });
}
test('Incomplete, extra, fractional, out-of-range and nonnumeric answers rejected', () => {
  const questions = fixture.banks['polarity-E'];
  const valid = { q0: 5, q1: 5, q2: 5, q3: 5 };
  for (const answers of [{ q0: 5 }, { ...valid, extra: 3 }, ...[0, 6, 2.5, '5', null].map((q0) => ({ ...valid, q0 }))]) {
    assert.throws(() => calculateMbti({ questions, answers }));
  }
  assert.throws(() => calculateMbti({ questions: [...questions, questions[0]], answers: valid }));
});
test('Preview snapshots editor data and never mutates questions or answers', () => {
  const questions = structuredClone(fixture.banks['polarity-E']);
  const answers = { q0: 5, q1: 5, q2: 5, q3: 5 };
  const bank = { title: 'Draft', version: 'v2', scoringVersion: mbtiScoringVersion, questions, questionIds: questions.map((q) => q.id) };
  const preview = createPreview('draft', bank);
  questions[0].text = 'Edited after preview';
  assert.notEqual(preview.questions[0].text, questions[0].text);
  assert.throws(() => { preview.questions[0].agreeWith = 'I'; });
  calculateMbti({ questions: preview.questions, answers });
  assert.deepEqual(answers, { q0: 5, q1: 5, q2: 5, q3: 5 });
  assert.throws(() => createPreview('draft', { ...bank, scoringVersion: 'unknown' }));
});
