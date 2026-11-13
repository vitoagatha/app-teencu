import { validateBank } from './mbtiBank.js';

export function draftContent(bank) {
  return {
    title: bank.title, version: bank.version, scoringVersion: 'teencu-centered-v1',
    questions: bank.questions.map(({ id, text, agreeWith }) => ({ id, text, agreeWith })),
    questionIds: bank.questions.map(({ id }) => id),
  };
}
export function fingerprint(value) {
  if (Array.isArray(value)) return `[${value.map(fingerprint).join(',')}]`;
  if (value && typeof value === 'object') return `{${Object.keys(value).sort().map((key) => `${JSON.stringify(key)}:${fingerprint(value[key])}`).join(',')}}`;
  return JSON.stringify(value);
}
export function validateDraft(id, bank) {
  const content = draftContent(bank);
  validateBank(id, content);
  return content;
}
export function moveQuestion(questions, index, direction) {
  const target = index + direction;
  if (target < 0 || target >= questions.length) return questions;
  const next = [...questions];
  [next[index], next[target]] = [next[target], next[index]];
  return next;
}
