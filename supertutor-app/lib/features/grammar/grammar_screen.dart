import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../core/theme.dart';
import '../../widgets/duo_button.dart';
import '../quiz/quiz_screen.dart';
import 'grammar_data.dart';

class GrammarListScreen extends StatelessWidget {
  const GrammarListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grammatika')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: grammarLessons.length,
        itemBuilder: (context, i) {
          final lesson = grammarLessons[i];
          final colors = [
            AppColors.secondary,
            AppColors.fire,
            AppColors.primary,
            AppColors.gold,
            AppColors.heart,
          ];
          final c = colors[i % colors.length];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => GrammarLessonScreen(lesson: lesson)),
              ),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(lesson.emoji,
                          style: const TextStyle(fontSize: 28)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(lesson.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(lesson.summary,
                              style: const TextStyle(
                                  color: AppColors.inkLight,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: c),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class GrammarLessonScreen extends StatelessWidget {
  final GrammarLesson lesson;
  const GrammarLessonScreen({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              width: 100,
              height: 100,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child:
                  Text(lesson.emoji, style: const TextStyle(fontSize: 60)),
            ),
          ),
          const SizedBox(height: 16),
          Text(lesson.title,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          MarkdownBody(
            data: lesson.content,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                  fontSize: 15, height: 1.5, fontWeight: FontWeight.w500),
              strong: const TextStyle(
                  fontWeight: FontWeight.w800, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 20),
          Text('Misollar', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...lesson.examples.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text('•  ',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800)),
                      Expanded(
                        child: Text(e,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontStyle: FontStyle.italic)),
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 24),
          DuoButton(
            label: 'Testni boshlash',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => QuizScreen(
                    subject: 'english', level: 'A2'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
