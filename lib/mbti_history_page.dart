import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'model/mbti_test.dart';
import 'services/mbti_repository.dart';

class MbtiHistoryScreen extends StatefulWidget {
  const MbtiHistoryScreen({super.key, this.repository});
  final MbtiRepository? repository;

  @override
  State<MbtiHistoryScreen> createState() => _MbtiHistoryScreenState();
}

class _MbtiHistoryScreenState extends State<MbtiHistoryScreen> {
  late final _repository = widget.repository ?? FirestoreMbtiRepository();
  final _entries = <MbtiHistoryEntry>[];
  Object? _cursor;
  bool _hasMore = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _repository.loadHistory(after: _cursor);
      if (!mounted) return;
      setState(() {
        final ids = _entries.map((entry) => entry.id).toSet();
        _entries.addAll(page.entries.where((entry) => !ids.contains(entry.id)));
        _cursor = page.cursor;
        _hasMore = page.hasMore;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Riwayat belum dapat dimuat. Periksa koneksi lalu coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat tes MBTI')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (_entries.isEmpty && !_loading && _error == null)
          const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                  'Belum ada riwayat tes. Hasil dari tes baru akan muncul di sini.')),
        for (final entry in _entries)
          Card(
              child: ListTile(
            title: Text(entry.type),
            subtitle: Text(
                'Versi ${entry.version}\n${DateFormat('dd MMM yyyy HH:mm').format(entry.completedAt)}'),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) =>
                  MbtiHistoryDetail(entry: entry, repository: _repository),
            )),
          )),
        if (_error != null) Text(_error!),
        if (_loading) const Center(child: CircularProgressIndicator()),
        if (!_loading && (_hasMore || _error != null))
          TextButton(
              onPressed: _load,
              child: Text(_error == null ? 'Muat berikutnya' : 'Coba lagi')),
      ]),
    );
  }
}

class MbtiHistoryDetail extends StatefulWidget {
  const MbtiHistoryDetail(
      {super.key, required this.entry, required this.repository});
  final MbtiHistoryEntry entry;
  final MbtiRepository repository;

  @override
  State<MbtiHistoryDetail> createState() => _MbtiHistoryDetailState();
}

class _MbtiHistoryDetailState extends State<MbtiHistoryDetail> {
  late Future<MbtiTestVersion> _version =
      widget.repository.loadVersion(widget.entry.testId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail hasil tes')),
      body: FutureBuilder<MbtiTestVersion>(
        future: _version,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Detail belum dapat dimuat.'),
              TextButton(
                  onPressed: () {
                    setState(() {
                      _version =
                          widget.repository.loadVersion(widget.entry.testId);
                    });
                  },
                  child: const Text('Coba lagi')),
            ]));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final test = snapshot.data!;
          MbtiSubmission result;
          try {
            result = MbtiSubmission(
                id: widget.entry.id,
                test: test,
                answers:
                    Map<String, int>.from(widget.entry.data['answers'] as Map));
            if (result.score.type != widget.entry.type ||
                test.version != widget.entry.version ||
                test.scoringVersion != widget.entry.data['scoringVersion'] ||
                !mapEquals(result.toMap()['dimensionScores'] as Map,
                    widget.entry.data['dimensionScores'] as Map)) {
              throw const FormatException(
                  'Riwayat tidak cocok dengan versi tes.');
            }
          } catch (_) {
            return const Center(
                child: Text('Data riwayat tidak dapat ditampilkan.'));
          }
          const ratings = [
            'Sangat Tidak Setuju',
            'Tidak Setuju',
            'Netral',
            'Setuju',
            'Sangat Setuju'
          ];
          return ListView(padding: const EdgeInsets.all(20), children: [
            Text(widget.entry.type,
                style:
                    const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            Text('${test.title} · versi ${test.version}'),
            Text(DateFormat('dd MMM yyyy HH:mm')
                .format(widget.entry.completedAt)),
            const SizedBox(height: 16),
            const Text('Skor per dimensi',
                style: TextStyle(fontWeight: FontWeight.bold)),
            for (final entry in result.score.scores.entries)
              Text('${entry.key.label}: ${entry.value}'),
            const Text('Positif: E/S/T/J · Negatif: I/N/F/P'),
            const SizedBox(height: 16),
            const Text('Jawaban saat tes',
                style: TextStyle(fontWeight: FontWeight.bold)),
            for (var index = 0; index < test.questions.length; index++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${index + 1}. ${test.questions[index].text}'),
                subtitle: Text(
                    ratings[result.answers[test.questions[index].id]! - 1]),
              ),
          ]);
        },
      ),
    );
  }
}
