import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:teencu/model/mbti_question.dart';
import 'package:teencu/services/mbti_scoring.dart';

void main() {
  final fixture = jsonDecode(
          File('test/fixtures/mbti-scoring-cases.json').readAsStringSync())
      as Map<String, dynamic>;
  test('Shared fixture uses the supported scoring algorithm', () {
    expect(fixture['scoringVersion'], mbtiScoringVersion);
  });
  for (final value in fixture['cases'] as List) {
    final scenario = value as Map<String, dynamic>;
    test('Shared Dart/JS scoring: ${scenario['name']}', () {
      final questions = (fixture['banks'][scenario['bank']] as List)
          .map((q) => MbtiQuestion(
                id: q['id'] as String,
                text: q['text'] as String,
                agreeWith: MbtiPreference.values
                    .byName((q['agreeWith'] as String).toLowerCase()),
              ))
          .toList();
      final result = calculateMbti(
          questions: questions,
          answers: Map<String, int>.from(scenario['answers'] as Map));
      final expected = scenario['expected'] as Map<String, dynamic>;
      expect(result.type, expected['type']);
      expect({
        for (final entry in result.scores.entries) entry.key.name: entry.value
      }, expected['scores']);
      expect(result.tiedDimensions.map((d) => d.name).toList(),
          expected['tiedDimensions']);
    });
  }
}
