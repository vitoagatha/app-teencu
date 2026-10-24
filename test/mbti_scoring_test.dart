import 'package:flutter_test/flutter_test.dart';
import 'package:teencu/data/mbti_questions.dart';
import 'package:teencu/model/mbti_question.dart';
import 'package:teencu/services/mbti_scoring.dart';

// Audit reference: agreement follows the meaning of each original statement.
const agreementLetters = [
  'E',
  'I',
  'E',
  'E',
  'E',
  'S',
  'S',
  'S',
  'S',
  'N',
  'T',
  'T',
  'T',
  'T',
  'F',
  'J',
  'J',
  'P',
  'P',
  'J',
];

Map<String, int> neutralAnswers() => {
      for (final question in mbtiQuestions) question.id: 3,
    };

Map<String, int> answersFor(String type) => {
      for (var i = 0; i < mbtiQuestions.length; i++)
        mbtiQuestions[i].id: type.contains(agreementLetters[i]) ? 5 : 1,
    };

void main() {
  test('Bank contains 20 uniquely identified questions and five per dimension',
      () {
    expect(mbtiQuestions, hasLength(20));
    expect(mbtiQuestions.map((q) => q.id).toSet(), hasLength(20));
    for (final dimension in MbtiDimension.values) {
      expect(
          mbtiQuestions.where((q) => q.dimension == dimension), hasLength(5));
    }
  });

  for (var i = 0; i < agreementLetters.length; i++) {
    test(
        'Question ${i + 1}: all five ratings follow ${agreementLetters[i]} direction',
        () {
      final dimension = MbtiDimension.values[i ~/ 5];
      final direction = agreementLetters[i] == dimension.first ? 1 : -1;
      for (var rating = 1; rating <= 5; rating++) {
        final answers = neutralAnswers()..[mbtiQuestions[i].id] = rating;
        final result =
            calculateMbti(questions: mbtiQuestions, answers: answers);
        expect(result.scores[dimension], (rating - 3) * direction);
        for (final other in MbtiDimension.values.where((d) => d != dimension)) {
          expect(result.scores[other], 0);
        }
      }
    });
  }

  for (final ei in ['E', 'I']) {
    for (final sn in ['S', 'N']) {
      for (final tf in ['T', 'F']) {
        for (final jp in ['J', 'P']) {
          final type = '$ei$sn$tf$jp';
          test('Consistent answers produce $type', () {
            final result = calculateMbti(
                questions: mbtiQuestions, answers: answersFor(type));
            expect(result.type, type);
            expect(result.tiedDimensions, isEmpty);
            expect(result.scores.values.map((score) => score.abs()),
                everyElement(10));
          });
        }
      }
    }
  }

  test('Neutral answers do not fabricate a personality type', () {
    final result =
        calculateMbti(questions: mbtiQuestions, answers: neutralAnswers());
    expect(result.scores.values, everyElement(0));
    expect(result.tiedDimensions, MbtiDimension.values);
    expect(result.type, isNull);
  });

  test('Opposing answers can tie even when not all answers are neutral', () {
    final answers = answersFor('ESTJ');
    // E: +2 + (-2) + 0 + 0 + 0 = 0.
    answers.addAll({'q01': 5, 'q02': 5, 'q03': 3, 'q04': 3, 'q05': 3});
    final result = calculateMbti(questions: mbtiQuestions, answers: answers);
    expect(result.tiedDimensions, [MbtiDimension.ei]);
    expect(result.type, isNull);
  });

  test('Strong agreement outweighs one weak opposing answer', () {
    final answers = neutralAnswers()..addAll({'q01': 5, 'q02': 4});
    final result = calculateMbti(questions: mbtiQuestions, answers: answers);
    expect(result.scores[MbtiDimension.ei], 1);
  });

  test('Reordering questions leaves scores and type unchanged', () {
    final answers = answersFor('INFP');
    final result = calculateMbti(
        questions: mbtiQuestions.reversed.toList(), answers: answers);
    expect(result.type, 'INFP');
    expect(result.scores.values, everyElement(-10));
  });

  test('Missing, extra, and substituted answer IDs are rejected', () {
    final missing = neutralAnswers()..remove('q01');
    final extra = neutralAnswers()..['unknown'] = 3;
    final wrong = neutralAnswers()
      ..remove('q01')
      ..['unknown'] = 3;
    for (final answers in [missing, extra, wrong]) {
      expect(() => calculateMbti(questions: mbtiQuestions, answers: answers),
          throwsArgumentError);
    }
  });

  test('Ratings outside the 1-5 scale are rejected', () {
    for (final rating in [0, 6, -1]) {
      final answers = neutralAnswers()..['q01'] = rating;
      expect(() => calculateMbti(questions: mbtiQuestions, answers: answers),
          throwsArgumentError);
    }
  });

  test('Empty bank, duplicate IDs and missing dimensions are rejected', () {
    for (final questions in [
      <MbtiQuestion>[],
      [...mbtiQuestions, mbtiQuestions.first],
      mbtiQuestions.where((q) => q.dimension != MbtiDimension.ei).toList(),
    ]) {
      expect(
          () => calculateMbti(questions: questions, answers: neutralAnswers()),
          throwsArgumentError);
    }
  });
}
