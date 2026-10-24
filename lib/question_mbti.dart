import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:flutter/material.dart';

import 'model/mbti_test.dart';
import 'model/mbti.dart';
import 'result_mbti.dart';
import 'services/mbti_scoring.dart';

class QuestionMbti extends StatefulWidget {
  const QuestionMbti(
      {super.key,
      required this.test,
      required this.sessionId,
      required this.saveResult});

  final MbtiTestVersion test;
  final String sessionId;
  final Future<void> Function(MbtiSubmission submission) saveResult;

  @override
  State<QuestionMbti> createState() => _QuestionMbtiState();
}

class _QuestionMbtiState extends State<QuestionMbti> {
  final Map<String, int> _answers = {};
  int _currentQuestionIndex = 0;
  bool _saving = false;
  String? _saveError;

  Future<void> _finishTest() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final score =
          calculateMbti(questions: widget.test.questions, answers: _answers);
      final type = score.type;
      if (type == null) {
        final dimensions = score.tiedDimensions.map((d) => d.label).join(', ');
        final review = await showDialog<bool>(
          context: context,
          useRootNavigator: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Hasil belum dapat ditentukan'),
            content: Text(
              'Jawaban pada dimensi $dimensions masih seimbang. '
              'Kamu dapat meninjau jawaban sesuai pengalamanmu atau '
              'kembali nanti. Hasil ini belum disimpan.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Kembali'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Tinjau jawaban'),
              ),
            ],
          ),
        );
        if (review == true && mounted) {
          setState(() {
            _currentQuestionIndex = widget.test.questions.indexWhere(
              (question) => score.tiedDimensions.contains(question.dimension),
            );
          });
        }
        return;
      }
      final data = _mbtiData(type);
      if (data == null) throw StateError('Deskripsi hasil belum tersedia.');
      // Stable for an exact retry, different if answers change after an error.
      final fingerprint = sha256
          .convert(utf8.encode(jsonEncode([
            widget.test.id,
            for (final question in widget.test.questions) _answers[question.id],
          ])))
          .toString()
          .substring(0, 16);
      await widget.saveResult(MbtiSubmission(
        id: '${widget.sessionId}_$fingerprint',
        test: widget.test,
        answers: _answers,
      ));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
        builder: (_) => ResultMbti(
          mbtiType: data.mbtiType,
          name: data.name,
          description: data.description,
          compatibleTypes: data.compatibleTypes,
        ),
      ));
    } catch (_) {
      if (mounted) {
        setState(() {
          _saveError =
              'Hasil belum berhasil disimpan. Periksa koneksi dan sesi login, lalu coba lagi. Jawabanmu masih tersedia.';
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.test.questions[_currentQuestionIndex];
    final answered = _answers.containsKey(question.id);
    final lastQuestion =
        _currentQuestionIndex == widget.test.questions.length - 1;
    const ratings = [
      'Sangat Tidak Setuju',
      'Tidak Setuju',
      'Netral',
      'Setuju',
      'Sangat Setuju',
    ];
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.pink,
          foregroundColor: Colors.white,
          title: const Text('Pertanyaan MBTI'),
          bottom: PreferredSize(
              preferredSize: const Size.fromHeight(24),
              child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('Versi ${widget.test.version}',
                      style: const TextStyle(color: Colors.white)))),
          leading: IconButton(
            tooltip: 'Kembali',
            onPressed: _saving ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              Image.asset('assets/teencu_logo.png', height: 60),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                    'Pertanyaan ${_currentQuestionIndex + 1} dari ${widget.test.questions.length}'),
              ),
              LinearProgressIndicator(
                value:
                    (_currentQuestionIndex + 1) / widget.test.questions.length,
                color: Colors.pink,
              ),
              Expanded(
                child: ListView(
                  key: ValueKey(question.id),
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      question.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink),
                    ),
                    const SizedBox(height: 20),
                    for (var index = 0; index < ratings.length; index++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _answers[question.id] == index + 1
                                ? Colors.pink
                                : Colors.white,
                            foregroundColor: _answers[question.id] == index + 1
                                ? Colors.white
                                : Colors.pink,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Colors.pink),
                          ),
                          onPressed: _saving
                              ? null
                              : () => setState(
                                  () => _answers[question.id] = index + 1),
                          child: Text(ratings[index]),
                        ),
                      ),
                  ],
                ),
              ),
              if (_saveError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(_saveError!),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saving || _currentQuestionIndex == 0
                            ? null
                            : () => setState(() => _currentQuestionIndex--),
                        child: const Text('Sebelumnya'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saving || !answered
                            ? null
                            : lastQuestion
                                ? _finishTest
                                : () => setState(() => _currentQuestionIndex++),
                        child: Text(_saving
                            ? 'Memproses...'
                            : lastQuestion
                                ? 'Selesai'
                                : 'Selanjutnya'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  MBTIType? _mbtiData(String name) {
    Map<String, MBTIType> mbtiDescriptions = {
      "ESTP": MBTIType(
        mbtiType: "ESTP",
        name: "ESTP (The Entrepreneur)",
        description:
            "ESTP adalah individu yang suka beraksi dan cepat dalam membuat keputusan. "
            "Mereka cenderung praktis dan sangat terampil dalam menangani situasi darurat.",
        compatibleTypes: ["ISTJ", "ISFJ", "ESTJ", "ESFP"],
      ),
      "ISTP": MBTIType(
        mbtiType: "ISTP",
        name: "ISTP (The Virtuoso)",
        description:
            "ISTP dikenal dengan pendekatan praktis dan logis terhadap masalah. "
            "Mereka lebih suka menyelesaikan masalah secara langsung dan memiliki keterampilan teknis yang luar biasa.",
        compatibleTypes: ["ESTP", "ESFP", "ISTJ", "INTJ"],
      ),
      "ESFP": MBTIType(
        mbtiType: "ESFP",
        name: "ESFP (The Entertainer)",
        description:
            "ESFP adalah individu yang penuh semangat, suka bersenang-senang, dan sangat sosial. "
            "Mereka menikmati hidup dan sangat peduli pada kebahagiaan orang lain.",
        compatibleTypes: ["ISFP", "ESTP", "ESFJ", "ENFJ"],
      ),
      "ISFP": MBTIType(
        mbtiType: "ISFP",
        name: "ISFP (The Adventurer)",
        description:
            "ISFP adalah pribadi yang sangat kreatif, dan mereka lebih suka menjalani hidup sesuai dengan nilai-nilai pribadi mereka. "
            "Mereka cenderung lebih tenang dan sering berfokus pada keindahan sekitar mereka.",
        compatibleTypes: ["ESFP", "INFP", "ISFJ"],
      ),
      "ESTJ": MBTIType(
        mbtiType: "ESTJ",
        name: "ESTJ (The Executive)",
        description:
            "ESTJ sangat terorganisir, terstruktur, dan berorientasi pada detail. "
            "Mereka sangat menghargai tradisi dan ingin memastikan bahwa segala sesuatunya berjalan dengan efisien.",
        compatibleTypes: ["ISTJ", "ISFJ", "ESFJ", "ENTJ"],
      ),
      "ISTJ": MBTIType(
        mbtiType: "ISTJ",
        name: "ISTJ (The Logistician)",
        description:
            "ISTJ adalah tipe yang sangat bertanggung jawab, disiplin, dan selalu mengutamakan pekerjaan yang sistematis dan terstruktur. "
            "Mereka sangat dapat diandalkan.",
        compatibleTypes: ["ESTJ", "ISFJ", "ENTJ"],
      ),
      "ESFJ": MBTIType(
        mbtiType: "ESFJ",
        name: "ESFJ (The Consul)",
        description:
            "ESFJ adalah tipe yang sangat peduli dan selalu berusaha membuat orang lain merasa nyaman. "
            "Mereka sangat sosial dan senang berinteraksi dengan banyak orang.",
        compatibleTypes: ["ISFJ", "ESTJ", "ENFJ"],
      ),
      "ISFJ": MBTIType(
        mbtiType: "ISFJ",
        name: "ISFJ (The Defender)",
        description:
            "ISFJ sangat peduli dengan orang lain, sangat perhatian, dan terorganisir. "
            "Mereka sering menjadi pendukung bagi teman-teman dan keluarga mereka.",
        compatibleTypes: ["ESFJ", "ESTJ", "ISFP"],
      ),
      "ENFP": MBTIType(
        mbtiType: "ENFP",
        name: "ENFP (The Inspirer)",
        description:
            "ENFP adalah individu yang antusias, bersemangat, dan sangat kreatif. "
            "Mereka memiliki banyak ide baru dan sering kali menginspirasi orang di sekitar mereka.",
        compatibleTypes: ["INFJ", "ENFJ", "INFP"],
      ),
      "INFP": MBTIType(
        mbtiType: "INFP",
        name: "INFP (The Mediator)",
        description:
            "INFP adalah tipe yang sangat idealis, empatik, dan lebih suka mengikuti naluri mereka daripada aturan. "
            "Mereka mencari makna dalam segala hal dan berusaha membuat dunia menjadi tempat yang lebih baik.",
        compatibleTypes: ["ENFJ", "ENFP", "ISFP"],
      ),
      "ENFJ": MBTIType(
        mbtiType: "ENFJ",
        name: "ENFJ (The Protagonist)",
        description:
            "ENFJ adalah seorang pemimpin yang berfokus pada orang lain dan sangat peduli dengan kebutuhan mereka. "
            "Mereka selalu berusaha menginspirasi orang lain untuk menjadi versi terbaik dari diri mereka.",
        compatibleTypes: ["INFJ", "ENFP", "INFP"],
      ),
      "INFJ": MBTIType(
        mbtiType: "INFJ",
        name: "INFJ (The Advocate)",
        description:
            "INFJ adalah pemimpi yang penuh kasih dan memiliki visi tentang dunia yang lebih baik. "
            "Mereka sangat berorientasi pada tujuan dan memiliki kemampuan untuk membantu orang lain mencapai potensi terbaik mereka.",
        compatibleTypes: ["ENFP", "ENFJ", "INFP"],
      ),
      "ENTP": MBTIType(
        mbtiType: "ENTP",
        name: "ENTP (The Debater)",
        description:
            "ENTP adalah seorang pendebat yang sangat cerdas dan kreatif. "
            "Mereka suka menganalisis ide-ide dan memikirkan cara-cara baru untuk memecahkan masalah.",
        compatibleTypes: ["INFJ", "ENFP", "INTP"],
      ),
      "INTP": MBTIType(
        mbtiType: "INTP",
        name: "INTP (The Thinker)",
        description: "INTP adalah tipe pemikir yang cerdas dan sangat logis. "
            "Mereka suka mengeksplorasi ide-ide baru dan berusaha memahami dunia dengan cara yang lebih mendalam.",
        compatibleTypes: ["ENTP", "ENTJ", "INTJ"],
      ),
      "ENTJ": MBTIType(
        mbtiType: "ENTJ",
        name: "ENTJ (The Commander)",
        description:
            "ENTJ adalah pemimpin alami yang sangat berorientasi pada tujuan dan sangat terorganisir. "
            "Mereka memiliki visi yang jelas dan berusaha mencapai tujuan dengan cara yang efisien dan tegas.",
        compatibleTypes: ["INTJ", "ENTP", "ESTJ"],
      ),
      "INTJ": MBTIType(
        mbtiType: "INTJ",
        name: "INTJ (The Architect)",
        description: "INTJ adalah seorang visioner yang sangat strategis. "
            "Mereka berfokus pada pencapaian tujuan jangka panjang dan sangat analitis dalam pendekatan mereka.",
        compatibleTypes: ["ENTP", "ENTJ", "INTP"],
      ),
    };
    return mbtiDescriptions[name];
  }
}
