import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../widgets/lesson_card.dart';
import '../../widgets/stat_chip.dart';
import '../../widgets/streak_banner.dart';
import '../auth/auth_controller.dart';
import '../dashboard/stats_repository.dart';

class _Subject {
  final String id;
  final String title;
  final String emoji;
  final Color accent;
  final String subtitle;
  final bool enabled;
  const _Subject({
    required this.id,
    required this.title,
    required this.emoji,
    required this.accent,
    required this.subtitle,
    required this.enabled,
  });
}

const _subjects = <_Subject>[
  _Subject(
      id: 'english',
      title: 'Ingliz tili',
      emoji: '🇬🇧',
      accent: AppColors.secondary,
      subtitle: '15 daqiqalik suhbat',
      enabled: true),
  _Subject(
      id: 'math',
      title: 'Matematika',
      emoji: '📐',
      accent: AppColors.fire,
      subtitle: 'Masalalar yechish',
      enabled: true),
  _Subject(
      id: 'russian',
      title: 'Rus tili',
      emoji: '🇷🇺',
      accent: AppColors.heart,
      subtitle: 'Suhbat + grammatika',
      enabled: true),
  _Subject(
      id: 'german',
      title: 'Nemis tili',
      emoji: '🇩🇪',
      accent: AppColors.gold,
      subtitle: 'A1 dan boshlang',
      enabled: true),
  _Subject(
      id: 'turkish',
      title: 'Turk tili',
      emoji: '🇹🇷',
      accent: AppColors.primary,
      subtitle: 'Tezkor o\'rganish',
      enabled: true),
];

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final statsAsync =
        auth.isAuthenticated ? ref.watch(myStatsProvider) : null;
    final streak = statsAsync?.maybeWhen(
            data: (s) => s.streakDays, orElse: () => 0) ??
        0;
    final totalMin =
        statsAsync?.maybeWhen(data: (s) => s.totalSeconds ~/ 60, orElse: () => 0) ??
            0;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            const Text('🦉', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 8),
            Text('SuperTutor',
                style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: StatChip(
              icon: Icons.local_fire_department_rounded,
              color: AppColors.fire,
              value: '$streak',
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: StatChip(
              icon: Icons.bolt_rounded,
              color: AppColors.gold,
              value: '$totalMin',
              label: 'min',
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (auth.isAuthenticated) ref.invalidate(myStatsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            StreakBanner(days: streak, cta: 'Davom etish', onCta: () {
              context.push('/chat/english');
            }),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Bugungi dars',
              subtitle: 'Tezda boshlang — 5 daqiqada',
            ),
            const SizedBox(height: 12),
            _ContinueCard(
              onTap: () => context.push('/chat/english'),
            ),
            const SizedBox(height: 28),
            _SectionHeader(
              title: 'Barcha fanlar',
              subtitle: '${_subjects.where((s) => s.enabled).length} ta mavjud',
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.9,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
              ),
              itemCount: _subjects.length,
              itemBuilder: (context, i) {
                final s = _subjects[i];
                return LessonCard(
                  emoji: s.emoji,
                  title: s.title,
                  subtitle: s.subtitle,
                  accent: s.accent,
                  locked: !s.enabled,
                  onTap: () => context.push('/chat/${s.id}'),
                );
              },
            ),
            const SizedBox(height: 16),
            _PromoCard(),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 2),
        Text(subtitle,
            style: const TextStyle(
                color: AppColors.inkLight, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ContinueCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.secondary, Color(0xFF0E80B5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondaryDark.withValues(alpha: 0.5),
              offset: const Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Text('💬', style: TextStyle(fontSize: 44)),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Suhbatni boshlash',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18)),
                  SizedBox(height: 2),
                  Text('AI bilan ingliz tilida real-time',
                      style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 26),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        children: [
          const Text('🎁', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hammasi bepul!',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                const Text(
                  'Reklamasiz, to\'lovsiz. Faqat o\'rganing.',
                  style: TextStyle(
                      color: AppColors.inkLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
