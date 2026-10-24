import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teencu/model/mbti_question.dart';
import 'package:teencu/model/mbti_test.dart';
import 'package:teencu/mbti_history_page.dart';
import 'package:teencu/mbti_test_page.dart';
import 'package:teencu/services/mbti_repository.dart';
import 'package:teencu/services/mbti_scoring.dart';

Map<String, dynamic> bank({String version = 'v1'}) => {
      'title': 'Bank $version',
      'version': version,
      'scoringVersion': mbtiScoringVersion,
      'status': 'published',
      'questionIds': ['a', 'b', 'c', 'd'],
      'questions': [
        {'id': 'a', 'text': 'Energi sosial $version', 'agreeWith': 'E'},
        {'id': 'b', 'text': 'Detail nyata $version', 'agreeWith': 'S'},
        {'id': 'c', 'text': 'Logika $version', 'agreeWith': 'T'},
        {'id': 'd', 'text': 'Rencana $version', 'agreeWith': 'J'},
      ],
    };
MbtiTestVersion version(String v) =>
    MbtiTestVersion.fromMap('mbti-$v', bank(version: v));

class FakeMbtiRepository implements MbtiRepository {
  MbtiTestVersion active = version('v1');
  bool fail = false;
  int loads = 0;
  int historyLoads = 0;
  String? requestedVersion;
  List<MbtiHistoryPage> pages = [const MbtiHistoryPage([])];
  @override
  String newSessionId() => 'test-session';
  @override
  Future<MbtiTestVersion> loadActiveTest() async {
    loads++;
    if (fail) throw Exception('offline');
    return active;
  }

  @override
  Future<MbtiTestVersion> loadVersion(String id) async {
    requestedVersion = id;
    return version(id == 'mbti-v1' ? 'v1' : 'v2');
  }

  @override
  Future<void> submit(MbtiSubmission submission) async {}
  @override
  Future<MbtiHistoryPage> loadHistory({Object? after}) async {
    if (fail) throw Exception('offline');
    return pages[historyLoads++];
  }
}

MbtiHistoryEntry history(String id) {
  final submission = MbtiSubmission(
      id: id, test: version('v1'), answers: {'a': 5, 'b': 5, 'c': 5, 'd': 5});
  return MbtiHistoryEntry(
      id: id, data: submission.toMap(), completedAt: DateTime(2026, 10, 24));
}

void main() {
  test('Published bank parses dynamic questions and rejects invalid schemas',
      () {
    final test = version('v1');
    expect(test.questions, hasLength(4));
    expect(test.questions.first.dimension, MbtiDimension.ei);
    for (final data in [
      bank()..['status'] = 'draft',
      bank()..['scoringVersion'] = 'unknown-algorithm',
      bank()..['questionIds'] = ['b', 'a', 'c', 'd'],
      bank()..['questions'] = [],
    ]) {
      expect(() => MbtiTestVersion.fromMap('mbti-v1', data), throwsA(anything));
    }
    expect(() => test.questions.clear(), throwsUnsupportedError);
  });
  test('Submission copies answers and records version, full answers and scores',
      () {
    final answers = {'a': 5, 'b': 5, 'c': 5, 'd': 5};
    final submission =
        MbtiSubmission(id: 'session', test: version('v1'), answers: answers);
    answers['a'] = 1;
    expect(submission.answers['a'], 5);
    expect(submission.toMap(), {
      'testId': 'mbti-v1',
      'testVersion': 'v1',
      'scoringVersion': mbtiScoringVersion,
      'answers': {'a': 5, 'b': 5, 'c': 5, 'd': 5},
      'dimensionScores': {'ei': 2, 'sn': 2, 'tf': 2, 'jp': 2},
      'resultType': 'ESTJ',
    });
    expect(
        () => MbtiSubmission(
            id: 'session',
            test: version('v1'),
            answers: {'a': 3, 'b': 3, 'c': 3, 'd': 3}),
        throwsArgumentError);
  });
  testWidgets(
      'Bank load retries, then active version stays pinned during the test',
      (tester) async {
    final repository = FakeMbtiRepository()..fail = true;
    await tester
        .pumpWidget(MaterialApp(home: MbtiTestPage(repository: repository)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Soal belum dapat dimuat'), findsOneWidget);
    repository.fail = false;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Pertanyaan 1 dari 4'), findsOneWidget);
    expect(find.text('Versi v1'), findsOneWidget);
    repository.active = version('v2');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Setuju'));
    await tester.pump();
    await tester.tap(find.text('Selanjutnya'));
    await tester.pump();
    expect(find.text('Detail nyata v1'), findsOneWidget);
    expect(repository.loads, 2);
  });
  testWidgets('History has an empty state and retry after a connection error',
      (tester) async {
    final repository = FakeMbtiRepository()..fail = true;
    await tester.pumpWidget(
        MaterialApp(home: MbtiHistoryScreen(repository: repository)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Riwayat belum dapat dimuat'), findsOneWidget);
    repository.fail = false;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Belum ada riwayat tes'), findsOneWidget);
  });
  testWidgets(
      'History paginates without duplicates and loads original version details',
      (tester) async {
    final repository = FakeMbtiRepository()..active = version('v2');
    repository.pages = [
      MbtiHistoryPage([history('one')], cursor: 'cursor1', hasMore: true),
      MbtiHistoryPage([history('one'), history('two')]),
    ];
    await tester.pumpWidget(
        MaterialApp(home: MbtiHistoryScreen(repository: repository)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Muat berikutnya'));
    await tester.pumpAndSettle();
    expect(find.text('ESTJ'), findsNWidgets(2));
    expect(repository.historyLoads, 2);
    await tester.tap(find.text('ESTJ').first);
    await tester.pumpAndSettle();
    expect(repository.requestedVersion, 'mbti-v1');
    expect(find.textContaining('Bank v1'), findsOneWidget);
    expect(find.textContaining('Energi sosial v1'), findsOneWidget);
    expect(find.text('Sangat Setuju'), findsNWidgets(4));
  });
}
