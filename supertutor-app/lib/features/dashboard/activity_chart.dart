import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';

final weeklyActivityProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) async {
    final r = await ref.read(dioProvider).get('/activity/weekly');
    final days = (r.data['days'] as List?) ?? const [];
    return days.map((d) => Map<String, dynamic>.from(d)).toList();
  },
);

class WeeklyActivityChart extends ConsumerWidget {
  const WeeklyActivityChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(weeklyActivityProvider);
    return async.when(
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (days) {
        if (days.isEmpty) return const SizedBox.shrink();
        final maxXp = days
                .map((d) => (d['earned_xp'] as int? ?? 0))
                .fold<int>(0, (a, b) => a > b ? a : b)
                .clamp(1, 1 << 30) +
            5;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Oxirgi 14 kun',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: days.map((d) {
                    final v = (d['earned_xp'] as int? ?? 0);
                    final h = (v / maxXp * 100).clamp(2.0, 100.0);
                    final target = d['target_xp'] as int? ?? 20;
                    final reached = v >= target;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: h.toDouble(),
                              decoration: BoxDecoration(
                                color: reached
                                    ? AppColors.primary
                                    : AppColors.gold,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                      width: 10,
                      height: 10,
                      color: AppColors.primary),
                  const SizedBox(width: 4),
                  const Text('Maqsadga yetdi',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.inkLight)),
                  const SizedBox(width: 12),
                  Container(width: 10, height: 10, color: AppColors.gold),
                  const SizedBox(width: 4),
                  const Text('XP olgan',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.inkLight)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
