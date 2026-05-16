import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';

class TeachbackScore {
  final int accuracy;
  final int completeness;
  final int clarity;
  final int fluency;
  final int overall;
  final List<String> strengths;
  final List<String> gaps;
  final String nextStep;

  const TeachbackScore({
    required this.accuracy,
    required this.completeness,
    required this.clarity,
    required this.fluency,
    required this.overall,
    required this.strengths,
    required this.gaps,
    required this.nextStep,
  });

  factory TeachbackScore.fromJson(Map<String, dynamic> j) => TeachbackScore(
        accuracy: (j['accuracy'] as num).toInt(),
        completeness: (j['completeness'] as num).toInt(),
        clarity: (j['clarity'] as num).toInt(),
        fluency: (j['fluency'] as num).toInt(),
        overall: (j['overall'] as num).toInt(),
        strengths: List<String>.from(j['strengths'] ?? const []),
        gaps: List<String>.from(j['gaps'] ?? const []),
        nextStep: (j['next_step'] as String?) ?? '',
      );
}

class TeachbackRepository {
  final Dio _dio;
  TeachbackRepository(this._dio);

  Future<TeachbackScore> evaluate({
    required String topic,
    String? reference,
    required String explanation,
  }) async {
    final r = await _dio.post('/teachback/evaluate', data: {
      'topic': topic,
      if (reference != null) 'reference': reference,
      'explanation': explanation,
    });
    return TeachbackScore.fromJson(Map<String, dynamic>.from(r.data));
  }
}

final teachbackRepositoryProvider = Provider<TeachbackRepository>(
  (ref) => TeachbackRepository(ref.watch(dioProvider)),
);
