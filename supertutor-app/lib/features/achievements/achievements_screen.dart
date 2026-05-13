import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../currency/currency_controller.dart';
import '../dashboard/stats_repository.dart';
import 'achievement_specs.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  AchievementStats _build(WidgetRef ref) {
    final stats = ref.watch(myStatsProvider).maybeWhen(
          data: (s) => s,
          orElse: () => null,
        );
    final currency = ref.watch(currencyControllerProvider);
    return AchievementStats(
      xpTotal: currency?.xpTotal ?? 0,
      streakDays: stats?.streakDays ?? 0,
      totalSessions: stats?.totalSessions ?? 0,
      totalMessages: stats?.totalMessages ?? 0,
      englishSessions: stats?.englishSessions ?? 0,
      mathSessions: stats?.mathSessions ?? 0,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = _build(ref);
    final earned = achievements.where((a) => a.check(s)).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Yutuqlar')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.35), width: 2),
              ),
              child: Row(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$earned / ${achievements.length} yutuqlar',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 18),
                        ),
                        Text(
                          earned == achievements.length
                              ? 'Hammasi qo\'lga kiritildi!'
                              : 'Davom eting — yana ${achievements.length - earned} ta',
                          style: const TextStyle(
                              color: AppColors.inkLight,
                              fontWeight: FontWeight.w600,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.05,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: achievements.length,
              itemBuilder: (context, i) {
                final a = achievements[i];
                final unlocked = a.check(s);
                return _BadgeCard(spec: a, unlocked: unlocked);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final AchievementSpec spec;
  final bool unlocked;
  const _BadgeCard({required this.spec, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: unlocked ? 1 : 0.45,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: unlocked
              ? spec.color.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unlocked
                ? spec.color.withValues(alpha: 0.5)
                : AppColors.border,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: unlocked ? spec.color : AppColors.inkLighter,
                shape: BoxShape.circle,
              ),
              child: Text(
                unlocked ? spec.emoji : '🔒',
                style: const TextStyle(fontSize: 28),
              ),
            ),
            const Spacer(),
            Text(
              spec.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              spec.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.inkLight,
                fontWeight: FontWeight.w500,
                fontSize: 11,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
