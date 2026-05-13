import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import 'quiz_models.dart';

class QuizRepository {
  final Dio _dio;
  QuizRepository(this._dio);

  Future<Quiz> generate({
    required String subject,
    String level = 'A2',
    int count = 5,
    String? topic,
  }) async {
    final r = await _dio.post('/quiz/generate', data: {
      'subject': subject,
      'level': level,
      'count': count,
      if (topic != null) 'topic': topic,
    });
    return Quiz.fromJson(Map<String, dynamic>.from(r.data));
  }

  Future<QuizResultSummary> submit({
    required Quiz quiz,
    required Map<String, int> answers,
  }) async {
    final r = await _dio.post('/quiz/submit', data: {
      'quiz_id': quiz.id,
      'subject': quiz.subject,
      'level': quiz.level,
      'questions': quiz.questions.map((q) => q.toJson()).toList(),
      'answers': answers.entries
          .map((e) => {'question_id': e.key, 'chosen_index': e.value})
          .toList(),
    });
    return QuizResultSummary.fromJson(Map<String, dynamic>.from(r.data));
  }
}

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return QuizRepository(ref.watch(dioProvider));
});
