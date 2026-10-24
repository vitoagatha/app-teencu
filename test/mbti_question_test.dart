import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teencu/question_mbti.dart';
import 'fixtures/mbti_fixture.dart';

QuestionMbti questionPage(
        {required Future<void> Function(String) saveResult}) =>
    QuestionMbti(
        test: localMbtiTest,
        sessionId: 'test-session',
        saveResult: (submission) => saveResult(submission.score.type!));

Future<void> answerTest(WidgetTester tester, List<int> ratings) async {
  const labels = [
    'Sangat Tidak Setuju',
    'Tidak Setuju',
    'Netral',
    'Setuju',
    'Sangat Setuju'
  ];
  for (var i = 0; i < ratings.length; i++) {
    final answer = find.widgetWithText(ElevatedButton, labels[ratings[i] - 1]);
    await tester.scrollUntilVisible(answer, 100,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(answer);
    await tester.pump();
    if (i != ratings.length - 1) {
      await tester.tap(find.text('Selanjutnya'));
      await tester.pump();
    }
  }
}

void main() {
  testWidgets(
      'Cannot skip unanswered question, and Back retains selected rating',
      (tester) async {
    await tester
        .pumpWidget(MaterialApp(home: questionPage(saveResult: (_) async {})));
    expect(
        tester
            .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Selanjutnya'))
            .onPressed,
        isNull);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Setuju'));
    await tester.pump();
    await tester.tap(find.text('Selanjutnya'));
    await tester.pump();
    expect(find.text('Pertanyaan 2 dari 20'), findsOneWidget);
    await tester.tap(find.text('Sebelumnya'));
    await tester.pump();
    expect(find.text('Pertanyaan 1 dari 20'), findsOneWidget);
    expect(
        tester
            .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Selanjutnya'))
            .onPressed,
        isNotNull);
  });

  testWidgets('All-neutral result is not saved and can be reviewed',
      (tester) async {
    final saved = <String>[];
    await tester
        .pumpWidget(MaterialApp(home: questionPage(saveResult: (type) async {
      saved.add(type);
    })));
    await answerTest(tester, List.filled(20, 3));
    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();
    expect(find.text('Hasil belum dapat ditentukan'), findsOneWidget);
    expect(find.textContaining('E/I, S/N, T/F, J/P'), findsOneWidget);
    expect(saved, isEmpty);
    await tester.tap(find.text('Tinjau jawaban'));
    await tester.pumpAndSettle();
    expect(find.text('Pertanyaan 1 dari 20'), findsOneWidget);
    expect(
        tester
            .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Selanjutnya'))
            .onPressed,
        isNotNull);
  });

  testWidgets(
      'Saving failure preserves answers; retry saves the calculated type once',
      (tester) async {
    final saved = <String>[];
    final completion = Completer<void>();
    Future<void> save(String type) async {
      saved.add(type);
      if (saved.length == 1) throw Exception('offline');
      await completion.future;
    }

    await tester.pumpWidget(MaterialApp(home: questionPage(saveResult: save)));
    await answerTest(
        tester, [5, 1, 5, 5, 5, 5, 5, 5, 5, 1, 5, 5, 5, 5, 1, 5, 5, 1, 1, 5]);
    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Jawabanmu masih tersedia.'), findsOneWidget);
    expect(find.text('Pertanyaan 20 dari 20'), findsOneWidget);
    await tester.tap(find.text('Selesai'));
    await tester.pump();
    expect(saved, ['ESTJ', 'ESTJ']);
    expect(
        tester
            .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Memproses...'))
            .onPressed,
        isNull);
    completion.complete();
    await tester.pumpAndSettle();
    expect(find.text('Hasil MBTI'), findsOneWidget);
    expect(find.text('ESTJ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
