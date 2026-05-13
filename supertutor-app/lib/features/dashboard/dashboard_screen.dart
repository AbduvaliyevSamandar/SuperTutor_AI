import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../widgets/duo_button.dart';
import '../auth/auth_controller.dart';
import 'stats_repository.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistika')),
      body: !AppConfig.supabaseConfigured || !auth.isAuthenticated
          ? const _GuestView()
          : const _StatsView(),
    );
  }
}

class _GuestView extends StatelessWidget {
  const _GuestView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📊', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('Statistikangizni saqlash uchun kiring',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            'O\'qish vaqti, streak, daraja — hammasini kuzating',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkLight, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          DuoButton(
            label: 'Kirish',
            onPressed: () => context.push('/login'),
          ),
        ],
      ),
    );
  }
}

class _StatsView extends ConsumerWidget {
  const _StatsView();

  String _fmt(int seconds) {
    final m = seconds ~/ 60;
    if (m < 60) return '${m}m';
    return '${m ~/ 60}h ${m % 60}m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStats = ref.watch(myStatsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(myStatsProvider.future),
      child: asyncStats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.heart),
            const SizedBox(height: 12),
            Text('Statistikani yuklab bo\'lmadi:\n$e',
                textAlign: TextAlign.center),
          ],
        ),
        data: (s) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: _BigStat(
                    color: AppColors.fire,
                    emoji: '🔥',
                    value: '${s.streakDays}',
                    label: 'Streak',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BigStat(
                    color: AppColors.gold,
                    emoji: '⭐',
                    value: '${s.totalMessages}',
                    label: 'XP',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _BigStat(
                    color: AppColors.primary,
                    emoji: '⏱️',
                    value: _fmt(s.totalSeconds),
                    label: 'Vaqt',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BigStat(
                    color: AppColors.secondary,
                    emoji: '🎯',
                    value: '${s.totalSessions}',
                    label: 'Sessiya',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Fanlar bo\'yicha',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _SubjectRow(
              emoji: '🇬🇧',
              title: 'Ingliz tili',
              meta: 'Daraja: ${s.englishLevel}',
              count: s.englishSessions,
              color: AppColors.secondary,
            ),
            const SizedBox(height: 10),
            _SubjectRow(
              emoji: '📐',
              title: 'Matematika',
              meta: 'Sessiyalar',
              count: s.mathSessions,
              color: AppColors.fire,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Text('🦉', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.streakDays == 0
                          ? 'Birinchi mashg\'ulotni boshlang — bugun!'
                          : 'Davom eting, siz a\'lo ish qilyapsiz!',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final Color color;
  final String emoji;
  final String value;
  final String label;
  const _BigStat({
    required this.color,
    required this.emoji,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 22)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.inkLight,
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
        ],
      ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  final String emoji;
  final String title;
  final String meta;
  final int count;
  final Color color;
  const _SubjectRow({
    required this.emoji,
    required this.title,
    required this.meta,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
                Text(meta,
                    style: const TextStyle(
                        color: AppColors.inkLight,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$count',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
