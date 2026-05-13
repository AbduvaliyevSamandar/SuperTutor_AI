import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../quiz/quiz_screen.dart';

class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Darslar')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Tezkor test',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text(
            'AI 5 ta savol tuzadi, javob bering — natija tahlil bilan.',
            style: TextStyle(
                color: AppColors.inkLight, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _QuizLauncher(
            emoji: '🇬🇧',
            title: 'Ingliz tili testi',
            subtitle: 'A2 daraja • 5 savol',
            color: AppColors.secondary,
            subject: 'english',
          ),
          const SizedBox(height: 10),
          _QuizLauncher(
            emoji: '🇷🇺',
            title: 'Rus tili testi',
            subtitle: 'A2 daraja • 5 savol',
            color: AppColors.heart,
            subject: 'russian',
          ),
          const SizedBox(height: 10),
          _QuizLauncher(
            emoji: '🇩🇪',
            title: 'Nemis tili testi',
            subtitle: 'A2 daraja • 5 savol',
            color: AppColors.gold,
            subject: 'german',
          ),
          const SizedBox(height: 10),
          _QuizLauncher(
            emoji: '🇹🇷',
            title: 'Turk tili testi',
            subtitle: 'A2 daraja • 5 savol',
            color: AppColors.primary,
            subject: 'turkish',
          ),
          const SizedBox(height: 10),
          _QuizLauncher(
            emoji: '📐',
            title: 'Matematika testi',
            subtitle: 'A2 daraja • 5 savol',
            color: AppColors.fire,
            subject: 'math',
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Text('📚', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 8),
                    Text('Strukturali darslar',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'A1 → C2 tartibida darslar tez orada. Hozircha chat va testlardan foydalaning.',
                  style: TextStyle(
                      color: AppColors.inkLight,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizLauncher extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final String subject;

  const _QuizLauncher({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.subject,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => QuizScreen(subject: subject)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 2),
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
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.inkLight,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}
