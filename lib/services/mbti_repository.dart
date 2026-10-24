import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../model/mbti_test.dart';

class MbtiHistoryEntry {
  const MbtiHistoryEntry(
      {required this.id, required this.data, required this.completedAt});
  final String id;
  final Map<String, dynamic> data;
  final DateTime completedAt;
  String get type => data['resultType'] as String;
  String get testId => data['testId'] as String;
  String get version => data['testVersion'] as String;
}

class MbtiHistoryPage {
  const MbtiHistoryPage(this.entries, {this.cursor, this.hasMore = false});
  final List<MbtiHistoryEntry> entries;
  final Object? cursor;
  final bool hasMore;
}

abstract class MbtiRepository {
  Future<MbtiTestVersion> loadActiveTest();
  Future<MbtiTestVersion> loadVersion(String id);
  String newSessionId();
  Future<void> submit(MbtiSubmission submission);
  Future<MbtiHistoryPage> loadHistory({Object? after});
}

class FirestoreMbtiRepository implements MbtiRepository {
  final _firestore = FirebaseFirestore.instance;
  final String _uid = FirebaseAuth.instance.currentUser!.uid;
  CollectionReference<Map<String, dynamic>> get _results =>
      _firestore.collection('users').doc(_uid).collection('mbti_results');

  @override
  String newSessionId() => _results.doc().id;

  @override
  Future<MbtiTestVersion> loadActiveTest() async {
    final config = await _firestore
        .doc('mbti_config/active')
        .get(const GetOptions(source: Source.server));
    final testId = config.data()?['testId'];
    if (testId is! String) throw StateError('Tes belum tersedia.');
    return loadVersion(testId);
  }

  @override
  Future<MbtiTestVersion> loadVersion(String id) async {
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,80}$').hasMatch(id)) {
      throw const FormatException('ID versi tes tidak valid.');
    }
    final snapshot = await _firestore
        .collection('mbti_tests')
        .doc(id)
        .get(const GetOptions(source: Source.server));
    final data = snapshot.data();
    if (data == null) throw StateError('Versi tes belum tersedia.');
    return MbtiTestVersion.fromMap(snapshot.id, data);
  }

  @override
  Future<void> submit(MbtiSubmission submission) async {
    if (FirebaseAuth.instance.currentUser?.uid != _uid) {
      throw StateError('Sesi login berubah.');
    }
    final reference = _results.doc(submission.id);
    final profile = _firestore.collection('users').doc(_uid);
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(reference);
      if (existing.exists) {
        final data = existing.data()!;
        if (data['testId'] != submission.test.id ||
            data['resultType'] != submission.score.type ||
            !mapEquals(Map<String, int>.from(data['answers'] as Map),
                submission.answers)) {
          throw StateError(
              'Sesi ini sudah disimpan dengan jawaban berbeda. Mulai tes baru.');
        }
        // A retry must not create another history row or move an old result
        // back to the top of the user's profile.
        return;
      }
      transaction.set(reference, {
        ...submission.toMap(),
        'completedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(profile, {
        'lastMbti': submission.score.type,
        'lastMbtiDate': FieldValue.serverTimestamp(),
        'lastMbtiResultId': submission.id,
      });
    });
  }

  @override
  Future<MbtiHistoryPage> loadHistory({Object? after}) async {
    Query<Map<String, dynamic>> query = _results
        .orderBy('completedAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(21);
    if (after != null) {
      query = query.startAfterDocument(after as DocumentSnapshot);
    }
    final snapshot = await query.get(const GetOptions(source: Source.server));
    final docs = snapshot.docs.take(20).toList();
    return MbtiHistoryPage([
      for (final doc in docs)
        MbtiHistoryEntry(
          id: doc.id,
          data: Map.unmodifiable(doc.data()),
          completedAt: (doc.data()['completedAt'] as Timestamp).toDate(),
        ),
    ],
        cursor: docs.isEmpty ? null : docs.last,
        hasMore: snapshot.docs.length > 20);
  }
}
