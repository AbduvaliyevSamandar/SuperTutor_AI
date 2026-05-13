import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../auth/auth_controller.dart';

final _leaderboardProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final r = await dio.get('/leaderboard/top', queryParameters: {'limit': 20});
  return (r.data['items'] as List?) ?? const [];
});

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final asyncBoard = ref.watch(_leaderboardProvider);
    final me = auth.session?.user.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: asyncBoard.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text('Yuklab bo\'lmadi:\n$e', textAlign: TextAlign.center),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('Hali hech kim XP yiqqani yo\'q.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final row = Map<String, dynamic>.from(items[i]);
              final rank = i + 1;
              final medal = switch (rank) {
                1 => '🥇',
                2 => '🥈',
                3 => '🥉',
                _ => '$rank',
              };
              final isMe = row['user_id'] == me;
              final name =
                  (row['display_name'] as String?) ?? 'Foydalanuvchi';
              final xp = row['xp_total'] ?? 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isMe
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isMe ? AppColors.primary : AppColors.border,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 36,
                      child: Text(medal,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800)),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        name.isNotEmpty
                            ? name.characters.first.toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isMe ? '$name (siz)' : name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text('$xp XP',
                        style: const TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
