import { validateBank } from './mbtiBank.js';

const dimensions = ['ei', 'sn', 'tf', 'jp'];
const poles = { ei: ['E', 'I'], sn: ['S', 'N'], tf: ['T', 'F'], jp: ['J', 'P'] };
const preferences = { E: ['ei', 1], I: ['ei', -1], S: ['sn', 1], N: ['sn', -1], T: ['tf', 1], F: ['tf', -1], J: ['jp', 1], P: ['jp', -1] };
export const mbtiScoringVersion = 'teencu-centered-v1';

export function calculateMbti({ questions, answers }) {
  validateBank('simulation', { title: 'Simulation', version: 'v1', scoringVersion: mbtiScoringVersion, questions, questionIds: questions.map((q) => q.id) });
  if (!answers || Array.isArray(answers) || Object.keys(answers).length !== questions.length || questions.some((q) => !Object.hasOwn(answers, q.id))) throw new Error('Semua soal harus dijawab, tanpa ID tambahan.');
  const scores = { ei: 0, sn: 0, tf: 0, jp: 0 };
  for (const question of questions) {
    const rating = answers[question.id];
    if (!Number.isInteger(rating) || rating < 1 || rating > 5) throw new Error('Jawaban harus bilangan bulat 1 sampai 5.');
    const [dimension, direction] = preferences[question.agreeWith];
    scores[dimension] += (rating - 3) * direction;
  }
  const tiedDimensions = dimensions.filter((dimension) => scores[dimension] === 0);
  return { scores, tiedDimensions, type: tiedDimensions.length ? null : dimensions.map((dimension) => poles[dimension][scores[dimension] > 0 ? 0 : 1]).join('') };
}

export function createPreview(id, bank) {
  validateBank(id, bank);
  return Object.freeze({ id, title: bank.title, version: bank.version, scoringVersion: bank.scoringVersion,
    questions: Object.freeze(bank.questions.map((q) => Object.freeze({ id: q.id, text: q.text, agreeWith: q.agreeWith }))),
  });
}
