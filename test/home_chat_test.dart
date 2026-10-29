import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teencu/home.dart';

Widget app(Future<String> Function() loadMbti) => MaterialApp(
      home: HomePage(
        loadMbti: loadMbti,
        chatBuilder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Chat page')),
        ),
      ),
    );

Future<void> tapChat(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(ElevatedButton, 'Chat'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Saved MBTI opens chat and leaves no warning on return',
      (tester) async {
    await tester.pumpWidget(app(() async => 'ESTJ'));
    await tapChat(tester);
    expect(find.text('Chat page'), findsOneWidget);
    expect(find.byType(AlertDialog, skipOffstage: false), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Tes MBTI'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets(
      'Missing result blocks chat; OK closes warning; new result is read',
      (tester) async {
    var savedMbti = '';
    await tester.pumpWidget(app(() async => savedMbti));
    await tapChat(tester);
    expect(find.textContaining('Kamu belum mengisi tes MBTI'), findsOneWidget);
    expect(find.text('Chat page'), findsNothing);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    savedMbti = 'INFP';
    await tapChat(tester);
    expect(find.text('Chat page'), findsOneWidget);
    expect(find.byType(AlertDialog, skipOffstage: false), findsNothing);
  });

  testWidgets('Read failure shows retry message without claiming no test',
      (tester) async {
    var fail = true;
    await tester.pumpWidget(app(() async {
      if (fail) throw StateError('offline');
      return 'ESTJ';
    }));
    await tapChat(tester);
    expect(
        find.textContaining('Status MBTI belum dapat dimuat'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Chat page'), findsNothing);
    fail = false;
    await tapChat(tester);
    expect(find.text('Chat page'), findsOneWidget);
  });

  testWidgets('Repeated taps while loading open only one chat route',
      (tester) async {
    final pending = Completer<String>();
    var reads = 0;
    await tester.pumpWidget(app(() {
      reads++;
      return pending.future;
    }));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Chat'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Chat'));
    await tester.pump();
    expect(reads, 1);
    expect(
        tester
            .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Chat'))
            .onPressed,
        isNull);
    pending.complete('INFP');
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Tes MBTI'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('Leaving home while reading does not navigate after disposal',
      (tester) async {
    final pending = Completer<String>();
    await tester.pumpWidget(app(() => pending.future));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Chat'));
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: Text('Signed out')));
    pending.complete('ESTJ');
    await tester.pumpAndSettle();
    expect(find.text('Signed out'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
