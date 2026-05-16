import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';

class CommuteStep {
  final String prompt_uz;
  final String target_en;
  final String hint;
  const CommuteStep({
    required this.prompt_uz,
    required this.target_en,
    this.hint = '',
  });
  factory CommuteStep.fromJson(Map<String, dynamic> j) => CommuteStep(
        prompt_uz: j['prompt_uz'] as String,
        target_en: j['target_en'] as String,
        hint: (j['hint'] as String?) ?? '',
      );
}

class CommuteLesson {
  final String title;
  final List<CommuteStep> steps;
  const CommuteLesson({required this.title, required this.steps});
  factory CommuteLesson.fromJson(Map<String, dynamic> j) => CommuteLesson(
        title: j['title'] as String,
        steps: (j['steps'] as List)
            .map((e) => CommuteStep.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class CommuteRepository {
  final Dio _dio;
  CommuteRepository(this._dio);

  Future<CommuteLesson> lesson({
    String language = 'english',
    String level = 'A2',
    String? topic,
    int nSteps = 10,
  }) async {
    final r = await _dio.post('/commute/lesson', data: {
      'language': language,
      'level': level,
      if (topic != null) 'topic': topic,
      'n_steps': nSteps,
    });
    return CommuteLesson.fromJson(Map<String, dynamic>.from(r.data));
  }
}

final commuteRepositoryProvider = Provider<CommuteRepository>(
  (ref) => CommuteRepository(ref.watch(dioProvider)),
);
