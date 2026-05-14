import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

class DailyWord {
  final String id;
  final String word;
  final String translationUz;
  final String language;
  const DailyWord({
    required this.id,
    required this.word,
    required this.translationUz,
    required this.language,
  });
  factory DailyWord.fromJson(Map<String, dynamic> j) => DailyWord(
        id: j['id'] ?? '',
        word: j['word'] ?? '',
        translationUz: j['translation_uz'] ?? '',
        language: j['language'] ?? 'en',
      );
}

class DailyLesson {
  final String subject;
  final String chatSeed;
  final String quizSubject;
  final List<DailyWord> srsWords;
  final bool chatDone;
  final bool quizDone;
  final bool srsDone;
  final int targetXp;

  const DailyLesson({
    required this.subject,
    required this.chatSeed,
    required this.quizSubject,
    required this.srsWords,
    required this.chatDone,
    required this.quizDone,
    required this.srsDone,
    required this.targetXp,
  });

  int get completedSteps =>
      (chatDone ? 1 : 0) + (quizDone ? 1 : 0) + (srsDone ? 1 : 0);
  bool get allDone => completedSteps >= 3;

  factory DailyLesson.fromJson(Map<String, dynamic> j) => DailyLesson(
        subject: j['subject'] ?? 'english',
        chatSeed: j['chat_seed'] ?? '',
        quizSubject: j['quiz_subject'] ?? 'english',
        srsWords: ((j['srs_words'] as List?) ?? const [])
            .map((w) => DailyWord.fromJson(Map<String, dynamic>.from(w)))
            .toList(),
        chatDone: j['chat_done'] ?? false,
        quizDone: j['quiz_done'] ?? false,
        srsDone: j['srs_done'] ?? false,
        targetXp: j['target_xp'] ?? 25,
      );
}

class DailyLessonRepository {
  final Dio _dio;
  DailyLessonRepository(this._dio);

  Future<DailyLesson> today() async {
    final r = await _dio.get('/daily-lesson/today');
    return DailyLesson.fromJson(Map<String, dynamic>.from(r.data));
  }

  Future<void> complete(String part) async {
    await _dio.post('/daily-lesson/complete', data: {'part': part});
  }
}

final dailyLessonRepoProvider = Provider<DailyLessonRepository>((ref) {
  return DailyLessonRepository(ref.watch(dioProvider));
});

final dailyLessonProvider =
    FutureProvider.autoDispose<DailyLesson>((ref) async {
  return ref.watch(dailyLessonRepoProvider).today();
});
