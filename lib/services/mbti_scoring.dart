import '../model/mbti_question.dart';

// Identifies these scoring rules for future versioned test sessions.
const mbtiScoringVersion = 'teencu-centered-v1';

class MbtiScore {
  MbtiScore._(Map<MbtiDimension, int> scores)
      : scores = Map.unmodifiable(scores);

  // Positive: E/S/T/J. Negative: I/N/F/P. Zero: no preference determined.
  final Map<MbtiDimension, int> scores;

  List<MbtiDimension> get tiedDimensions => [
        for (final dimension in MbtiDimension.values)
          if (scores[dimension] == 0) dimension,
      ];

  String? get type {
    if (tiedDimensions.isNotEmpty) return null;
    return [
      for (final dimension in MbtiDimension.values)
        scores[dimension]! > 0 ? dimension.first : dimension.second,
    ].join();
  }
}

MbtiScore calculateMbti({
  required List<MbtiQuestion> questions,
  required Map<String, int> answers,
}) {
  final ids = questions.map((question) => question.id).toSet();
  if (questions.isEmpty || ids.length != questions.length || ids.contains('')) {
    throw ArgumentError('Soal harus memiliki ID unik dan tidak boleh kosong.');
  }
  for (final dimension in MbtiDimension.values) {
    if (!questions.any((question) => question.dimension == dimension)) {
      throw ArgumentError('Tidak ada soal untuk dimensi ${dimension.label}.');
    }
  }
  if (answers.length != ids.length || !ids.containsAll(answers.keys)) {
    throw ArgumentError('Semua soal harus dijawab, tanpa ID jawaban tambahan.');
  }
  final scores = {for (final dimension in MbtiDimension.values) dimension: 0};
  for (final question in questions) {
    final rating = answers[question.id];
    if (rating == null || rating < 1 || rating > 5) {
      throw ArgumentError('Jawaban ${question.id} harus bernilai 1 sampai 5.');
    }
    scores[question.dimension] = scores[question.dimension]! +
        (rating - 3) * question.agreeWith.direction;
  }
  return MbtiScore._(scores);
}
