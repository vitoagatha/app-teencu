import 'dart:convert';
import 'dart:io';

import 'package:teencu/data/mbti_questions.dart';
import 'package:teencu/services/mbti_scoring.dart';

void main() {
  final seed = {
    'title': 'Eksplorasi kepribadian Teencu',
    'version': 'v1',
    'scoringVersion': mbtiScoringVersion,
    'questions': [
      for (final q in mbtiQuestions)
        {
          'id': q.id,
          'text': q.text,
          'agreeWith': q.agreeWith.name.toUpperCase()
        }
    ],
  };
  File('seed/mbti-v1.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(seed)}\n');
  stdout.writeln(
      'Seed lokal dibuat: seed/mbti-v1.json. Belum ada perubahan di cloud.');
}
