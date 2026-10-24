import '../services/mbti_scoring.dart';
import 'mbti_question.dart';

class MbtiTestVersion {
  MbtiTestVersion({
    required this.id,
    required this.title,
    required this.version,
    required this.scoringVersion,
    required List<MbtiQuestion> questions,
  }) : questions = List.unmodifiable(questions) {
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,80}$').hasMatch(id) ||
        title.trim().isEmpty ||
        title.length > 160 ||
        version.trim().isEmpty ||
        version.length > 80 ||
        scoringVersion != mbtiScoringVersion ||
        questions.length < 4 ||
        questions.length > 80) {
      throw const FormatException('Versi tes belum didukung atau tidak valid.');
    }
    for (final question in questions) {
      if (!RegExp(r'^[a-zA-Z0-9_-]{1,80}$').hasMatch(question.id) ||
          question.text.trim().isEmpty ||
          question.text.length > 1000) {
        throw const FormatException('Soal tidak valid.');
      }
    }
    calculateMbti(
        questions: questions, answers: {for (final q in questions) q.id: 3});
  }

  final String id;
  final String title;
  final String version;
  final String scoringVersion;
  final List<MbtiQuestion> questions;

  factory MbtiTestVersion.fromMap(String id, Map<String, dynamic> data) {
    if (data['status'] != 'published' ||
        data['questions'] is! List ||
        data['questionIds'] is! List) {
      throw const FormatException('Versi tes belum dipublikasikan.');
    }
    final questions = (data['questions'] as List).map((value) {
      final item = Map<String, dynamic>.from(value as Map);
      return MbtiQuestion(
        id: item['id'] as String,
        text: item['text'] as String,
        agreeWith: MbtiPreference.values
            .byName((item['agreeWith'] as String).toLowerCase()),
      );
    }).toList();
    final ids = List<String>.from(data['questionIds'] as List);
    if (ids.length != questions.length ||
        !List.generate(ids.length, (i) => ids[i] == questions[i].id)
            .every((v) => v)) {
      throw const FormatException('Daftar ID soal tidak cocok.');
    }
    return MbtiTestVersion(
      id: id,
      title: data['title'] as String,
      version: data['version'] as String,
      scoringVersion: data['scoringVersion'] as String,
      questions: questions,
    );
  }
}

class MbtiSubmission {
  MbtiSubmission(
      {required this.id, required this.test, required Map<String, int> answers})
      : answers = Map.unmodifiable(answers),
        score = calculateMbti(questions: test.questions, answers: answers) {
    if (score.type == null) throw ArgumentError('Hasil masih seimbang.');
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,80}$').hasMatch(id)) {
      throw ArgumentError('ID sesi tidak valid.');
    }
  }

  final String id;
  final MbtiTestVersion test;
  final Map<String, int> answers;
  final MbtiScore score;

  Map<String, dynamic> toMap() => {
        'testId': test.id,
        'testVersion': test.version,
        'scoringVersion': test.scoringVersion,
        'answers': answers,
        'dimensionScores': {
          for (final entry in score.scores.entries) entry.key.name: entry.value
        },
        'resultType': score.type!,
      };
}
