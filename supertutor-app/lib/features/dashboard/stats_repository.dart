import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

class UserStats {
  final int totalSessions;
  final int totalSeconds;
  final int totalMessages;
  final int englishSessions;
  final int mathSessions;
  final int streakDays;
  final String englishLevel;

  const UserStats({
    this.totalSessions = 0,
    this.totalSeconds = 0,
    this.totalMessages = 0,
    this.englishSessions = 0,
    this.mathSessions = 0,
    this.streakDays = 0,
    this.englishLevel = 'A1',
  });

  factory UserStats.fromJson(Map<String, dynamic> j) => UserStats(
        totalSessions: j['total_sessions'] ?? 0,
        totalSeconds: j['total_seconds'] ?? 0,
        totalMessages: j['total_messages'] ?? 0,
        englishSessions: j['english_sessions'] ?? 0,
        mathSessions: j['math_sessions'] ?? 0,
        streakDays: j['streak_days'] ?? 0,
        englishLevel: j['english_level'] ?? 'A1',
      );
}

class StatsRepository {
  final Dio _dio;
  StatsRepository(this._dio);

  Future<UserStats> myStats() async {
    final r = await _dio.get('/stats/me');
    return UserStats.fromJson(Map<String, dynamic>.from(r.data));
  }

  Future<String> startSession(String subject) async {
    final r = await _dio.post('/sessions', data: {'subject': subject});
    return r.data['id'] as String;
  }

  Future<void> updateSession(String id,
      {required int durationSeconds, required int messagesCount}) async {
    await _dio.patch('/sessions/$id', data: {
      'duration_seconds': durationSeconds,
      'messages_count': messagesCount,
    });
  }

  Future<void> endSession(String id) async {
    await _dio.post('/sessions/$id/end');
  }
}

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository(ref.watch(dioProvider));
});

final myStatsProvider = FutureProvider<UserStats>((ref) async {
  return ref.watch(statsRepositoryProvider).myStats();
});
