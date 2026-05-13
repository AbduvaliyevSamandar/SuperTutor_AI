import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../widgets/stat_chip.dart';
import '../../widgets/streak_banner.dart';
import '../auth/auth_controller.dart';
import '../dashboard/stats_repository.dart';

enum _NodeStatus { completed, current, locked }

class _LessonNode {
  final String emoji;
  final String title;
  final String subject;
  final Color color;
  final _NodeStatus status;
  const _LessonNode(
    this.emoji,
    this.title,
    this.subject,
    this.color,
    this.status,
  );
}

class SkillTreeScreen extends ConsumerWidget {
  const SkillTreeScreen({super.key});

  static const _nodes = <_LessonNode>[
    _LessonNode('🇬🇧', 'Ingliz: salomlashish', 'english', AppColors.secondary, _NodeStatus.current),
    _LessonNode('🇬🇧', 'Ingliz: oddiy savollar', 'english', AppColors.secondary, _NodeStatus.locked),
    _LessonNode('🇬🇧', 'Ingliz: oilam', 'english', AppColors.secondary, _NodeStatus.locked),
    _LessonNode('📐', 'Matematika: 4 amal', 'math', AppColors.fire, _NodeStatus.locked),
    _LessonNode('🇷🇺', 'Rus tili: tanishuv', 'russian', AppColors.heart, _NodeStatus.locked),
    _LessonNode('🇩🇪', 'Nemis: alifbo', 'german', AppColors.gold, _NodeStatus.locked),
    _LessonNode('🇹🇷', 'Turk: oddiy gap', 'turkish', AppColors.primary, _NodeStatus.locked),
  ];

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
            Image.asset('assets/icon/icon_fg.png', width: 36, height: 36),
            const SizedBox(width: 8),
            Text('SuperTutor', style: Theme.of(context).textTheme.titleLarge),
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
            padding: const EdgeInsets.only(right: 8),
            child: StatChip(
              icon: Icons.bolt_rounded,
              color: AppColors.gold,
              value: '$totalMin',
              label: 'min',
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: StatChip(
              icon: Icons.favorite_rounded,
              color: AppColors.heart,
              value: '5',
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (auth.isAuthenticated) ref.invalidate(myStatsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: StreakBanner(
                days: streak,
                cta: 'Boshlash',
                onCta: () => context.push('/chat/english'),
              ),
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
              return _SkillNode(
                node: _nodes[i],
                index: i,
                onTap: _nodes[i].status == _NodeStatus.locked
                    ? null
                    : () => context.push('/chat/${_nodes[i].subject}'),
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
  final VoidCallback? onTap;

  const _SkillNode({
    required this.node,
    required this.index,
    required this.onTap,
  });

  static const _amplitude = 60.0;

  Color get _ringColor => switch (node.status) {
        _NodeStatus.completed => AppColors.primary,
        _NodeStatus.current => node.color,
        _NodeStatus.locked => AppColors.borderDark,
      };

  Color get _bgColor => switch (node.status) {
        _NodeStatus.completed => AppColors.primary,
        _NodeStatus.current => node.color,
        _NodeStatus.locked => AppColors.surface,
      };

  IconData get _statusIcon => switch (node.status) {
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
                      if (node.status != _NodeStatus.current)
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
                  color: node.status == _NodeStatus.locked
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
