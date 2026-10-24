import 'package:teencu/data/mbti_questions.dart';
import 'package:teencu/model/mbti_test.dart';
import 'package:teencu/services/mbti_scoring.dart';

final localMbtiTest = MbtiTestVersion(
  id: 'mbti-v1',
  title: 'Tes MBTI',
  version: 'v1',
  scoringVersion: mbtiScoringVersion,
  questions: mbtiQuestions,
);
