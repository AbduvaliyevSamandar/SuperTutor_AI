import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import 'daily_lesson_repository.dart';

class DailyLessonCard extends ConsumerWidget {
  const DailyLessonCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(authControllerProvider).isAuthenticated) {
      return const SizedBox.shrink();
    }
    final async = ref.watch(dailyLessonProvider);
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (lesson) => _Card(lesson: lesson, ref: ref),
    );
  }
}

class _Card extends StatelessWidget {
  final DailyLesson lesson;
  final WidgetRef ref;
  const _Card({required this.lesson, required this.ref});

  @override
  Widget build(BuildContext context) {
    final done = lesson.completedSteps;
    final progress = done / 3.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B5BE5), Color(0xFF4A3DC6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A3DC6).withValues(alpha: 0.5),
            offset: const Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📅', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Bugungi dars',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18)),
              ),
              Text('$done/3',
                  style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor:
                  const AlwaysStoppedAnimation(Color(0xFFFFC800)),
            ),
          ),
          const SizedBox(height: 14),
          _Step(
            emoji: '💬',
            title: 'AI bilan suhbat',
            subtitle: '5 ta xabar',
            done: lesson.chatDone,
            onTap: () => context.push(
              '/chat/${lesson.subject}?seed=${Uri.encodeComponent(lesson.chatSeed)}',
            ),
          ),
          const SizedBox(height: 6),
          _Step(
            emoji: '🎯',
            title: 'Tezkor test',
            subtitle: '5 savol',
            done: lesson.quizDone,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Darslar tab → Tezkor test bo\'limidan ishlatib boring.')),
              );
            },
          ),
          const SizedBox(height: 6),
          _Step(
            emoji: '🔁',
            title: 'So\'z takrori',
            subtitle: lesson.srsWords.isEmpty
                ? 'Hozir takror yo\'q'
                : '${lesson.srsWords.length} so\'z',
            done: lesson.srsDone,
            disabled: lesson.srsWords.isEmpty,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Darslar tab → So\'z takrori bo\'limidan ishlatib boring.')),
              );
            },
          ),
          if (lesson.allDone) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('🎉 Bugungi dars tugadi!',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800)),
            ),
          ],
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool done;
  final bool disabled;
  final VoidCallback onTap;
  const _Step({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.done,
    this.disabled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.55 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: done ? 0.22 : 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14)),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: 11)),
                  ],
                ),
              ),
              done
                  ? const Icon(Icons.check_circle,
                      color: Color(0xFFFFC800), size: 22)
                  : const Icon(Icons.arrow_forward_ios,
                      color: Colors.white70, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
