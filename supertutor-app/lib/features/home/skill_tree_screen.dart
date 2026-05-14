import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../widgets/duo_button.dart';
import '../../widgets/stat_chip.dart';
import '../../widgets/streak_banner.dart';
import '../auth/auth_controller.dart';
import '../currency/currency_controller.dart';
import '../daily/daily_lesson_card.dart';
import '../dashboard/stats_repository.dart';
import 'word_of_the_day.dart';

enum _NodeStatus { completed, current, locked }

class _LessonNode {
  final String emoji;
  final String title;
  final String subject;
  final Color color;
  /// Number of completed sessions of `subject` required for this node to be CURRENT.
  final int unlockAfter;
  const _LessonNode(
    this.emoji,
    this.title,
    this.subject,
    this.color,
    this.unlockAfter,
  );
}

class SkillTreeScreen extends ConsumerWidget {
  const SkillTreeScreen({super.key});

  static const _nodes = <_LessonNode>[
    _LessonNode('🇬🇧', 'Salomlashish', 'english', AppColors.secondary, 0),
    _LessonNode('🇬🇧', 'Oddiy savollar', 'english', AppColors.secondary, 1),
    _LessonNode('🇬🇧', 'Oila va do\'stlar', 'english', AppColors.secondary, 2),
    _LessonNode('🇬🇧', 'Sevimli ishlar', 'english', AppColors.secondary, 3),
    _LessonNode('📐', 'Matematika asoslari', 'math', AppColors.fire, 0),
    _LessonNode('🇷🇺', 'Rus tili: tanishuv', 'russian', AppColors.heart, 0),
    _LessonNode('🇩🇪', 'Nemis: alifbo', 'german', AppColors.gold, 0),
    _LessonNode('🇹🇷', 'Turk tili: salom', 'turkish', AppColors.primary, 0),
  ];

  int _sessionsFor(String subject, dynamic stats) {
    if (stats == null) return 0;
    switch (subject) {
      case 'english':
        return (stats.englishSessions as int?) ?? 0;
      case 'math':
        return (stats.mathSessions as int?) ?? 0;
      default:
        return 0;
    }
  }

  _NodeStatus _statusFor(_LessonNode node, dynamic stats) {
    final done = _sessionsFor(node.subject, stats);
    if (done > node.unlockAfter) return _NodeStatus.completed;
    if (done == node.unlockAfter) return _NodeStatus.current;
    return _NodeStatus.locked;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final statsAsync =
        auth.isAuthenticated ? ref.watch(myStatsProvider) : null;
    final stats =
        statsAsync?.maybeWhen(data: (s) => s, orElse: () => null);
    final streak = stats?.streakDays ?? 0;
    final currency = ref.watch(currencyControllerProvider);
    final hearts = currency?.hearts ?? 5;
    final xp = currency?.xpTotal ?? 0;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Image.asset('assets/icon/icon_fg.png', width: 32, height: 32),
            const SizedBox(width: 6),
            Text('SuperTutor', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: StatChip(
              icon: Icons.local_fire_department_rounded,
              color: AppColors.fire,
              value: '$streak',
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: StatChip(
              icon: Icons.bolt_rounded,
              color: AppColors.gold,
              value: '$xp',
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: hearts == 0 && auth.isAuthenticated
                  ? () => _showHeartsModal(context, ref)
                  : null,
              child: StatChip(
                icon: Icons.favorite_rounded,
                color: AppColors.heart,
                value: '$hearts',
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (auth.isAuthenticated) {
            ref.invalidate(myStatsProvider);
            await ref.read(currencyControllerProvider.notifier).refresh();
          }
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
          children: [
            const SizedBox(height: 8),
            const Center(child: AnimatedMascot(size: 90)),
            const SizedBox(height: 12),
            if (auth.isAuthenticated && currency != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: _DailyGoalCard(currency: currency, ref: ref),
              ),
            if (auth.isAuthenticated)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: DailyLessonCard(),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: StreakBanner(
                days: streak,
                cta: 'Boshlash',
                onCta: () => context.push('/chat/english'),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: WordOfTheDayCard(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
              child: Text(
                'Bo\'lim 1 · Asoslar',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                'Har bir nuqtani tegib, suhbatni boshlang. Yo\'l yuqoridan pastga.',
                style: TextStyle(
                  color: AppColors.inkLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...List.generate(_nodes.length, (i) {
              final node = _nodes[i];
              final status = _statusFor(node, stats);
              return _SkillNode(
                node: node,
                index: i,
                status: status,
                onTap: status == _NodeStatus.locked
                    ? () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Avval ${node.subject} bo\'yicha oldingi darslarni tugating.')),
                        )
                    : () {
                        if (hearts <= 0 && auth.isAuthenticated) {
                          _showHeartsModal(context, ref);
                        } else {
                          context.push('/chat/${node.subject}');
                        }
                      },
              );
            }),
            const SizedBox(height: 24),
            _SectionFooter(),
          ],
        ),
      ),
    );
  }
}

class _SkillNode extends StatelessWidget {
  final _LessonNode node;
  final int index;
  final _NodeStatus status;
  final VoidCallback? onTap;

  const _SkillNode({
    required this.node,
    required this.index,
    required this.status,
    required this.onTap,
  });

  static const _amplitude = 60.0;

  Color get _ringColor => switch (status) {
        _NodeStatus.completed => AppColors.primary,
        _NodeStatus.current => node.color,
        _NodeStatus.locked => AppColors.borderDark,
      };

  Color get _bgColor => switch (status) {
        _NodeStatus.completed => AppColors.primary,
        _NodeStatus.current => node.color,
        _NodeStatus.locked => AppColors.surface,
      };

  IconData get _statusIcon => switch (status) {
        _NodeStatus.completed => Icons.check_rounded,
        _NodeStatus.current => Icons.star_rounded,
        _NodeStatus.locked => Icons.lock_rounded,
      };

  @override
  Widget build(BuildContext context) {
    // Sinusoidal x-offset to wind left-right.
    final dx = math.sin(index * 0.9) * _amplitude;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Transform.translate(
        offset: Offset(dx, 0),
        child: Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: _bgColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: _ringColor, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: _ringColor.withValues(alpha: 0.85),
                        offset: const Offset(0, 6),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(node.emoji, style: const TextStyle(fontSize: 36)),
                      if (status != _NodeStatus.current)
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: _ringColor, width: 1.5),
                            ),
                            child: Icon(_statusIcon,
                                size: 12, color: _ringColor),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                node.title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: status == _NodeStatus.locked
                      ? AppColors.inkLighter
                      : AppColors.ink,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Text('🏆', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Keyingi bo\'lim qulflanmoqda...\nDarslarni tamomlang!',
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14, height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyGoalCard extends StatelessWidget {
  final dynamic currency;
  final WidgetRef ref;
  const _DailyGoalCard({required this.currency, required this.ref});

  @override
  Widget build(BuildContext context) {
    final progress = (currency.dailyProgress as double).clamp(0.0, 1.0);
    final reached = currency.dailyGoalReached as bool;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showSetGoalSheet(context, ref, currency.dailyTargetXp),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(reached ? '🎉' : '🎯',
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Kunlik maqsad',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                ),
                Text(
                  '${currency.dailyEarnedXp} / ${currency.dailyTargetXp} XP',
                  style: TextStyle(
                      color: reached ? AppColors.primary : AppColors.inkLight,
                      fontWeight: FontWeight.w800,
                      fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(
                  reached ? AppColors.primary : AppColors.gold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showSetGoalSheet(BuildContext context, WidgetRef ref, int currentTarget) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kunlik maqsad tanlang',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 4),
            const Text('Har kuni shu XP miqdorini olishingiz kerak',
                style: TextStyle(color: AppColors.inkLight)),
            const SizedBox(height: 16),
            for (final t in [10, 20, 50, 100])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref
                        .read(currencyControllerProvider.notifier)
                        .setGoal(t);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: currentTarget == t
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: currentTarget == t
                              ? AppColors.primary
                              : AppColors.border,
                          width: 2),
                    ),
                    child: Row(
                      children: [
                        Text(
                          t == 10
                              ? '🌱'
                              : t == 20
                                  ? '⚡'
                                  : t == 50
                                      ? '🔥'
                                      : '🚀',
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('$t XP',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16)),
                        ),
                        Text(
                          t == 10
                              ? 'Yengil'
                              : t == 20
                                  ? 'Oddiy'
                                  : t == 50
                                      ? 'Kuchli'
                                      : 'Pro',
                          style: const TextStyle(
                              color: AppColors.inkLight,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

void _showHeartsModal(BuildContext context, WidgetRef ref) {
  final currency = ref.read(currencyControllerProvider);
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💔', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 8),
            Text('Yuraklar tugadi',
                style: Theme.of(ctx).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              currency == null
                  ? 'Biroz dam oling'
                  : 'Keyingi yurak ${(currency.nextHeartInSeconds / 60).ceil()} daqiqada.',
              style: const TextStyle(
                  color: AppColors.inkLight, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            DuoButton(
              label: '350 💎 — Yuraklarni to\'ldirish',
              variant: DuoButtonVariant.gold,
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await ref
                    .read(currencyControllerProvider.notifier)
                    .refillHearts();
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gemma yetarli emas')),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
            DuoButton(
              label: 'Yopish',
              variant: DuoButtonVariant.outline,
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    ),
  );
}
