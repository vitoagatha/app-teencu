import 'package:flutter/material.dart';

import 'model/mbti_test.dart';
import 'question_mbti.dart';
import 'services/mbti_repository.dart';

class MbtiTestPage extends StatefulWidget {
  const MbtiTestPage({super.key, this.repository});
  final MbtiRepository? repository;

  @override
  State<MbtiTestPage> createState() => _MbtiTestPageState();
}

class _MbtiTestPageState extends State<MbtiTestPage> {
  late final _repository = widget.repository ?? FirestoreMbtiRepository();
  late Future<MbtiTestVersion> _test = _repository.loadActiveTest();
  late final _sessionId = _repository.newSessionId();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MbtiTestVersion>(
      future: _test,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Tes MBTI')),
            body: Center(
                child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text(
                    'Soal belum dapat dimuat. Periksa koneksi atau coba kembali nanti.',
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _test = _repository.loadActiveTest();
                      });
                    },
                    child: const Text('Coba lagi')),
              ]),
            )),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        return QuestionMbti(
            test: snapshot.data!,
            sessionId: _sessionId,
            saveResult: _repository.submit);
      },
    );
  }
}
