import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'vocab_topics.dart';

class VocabTopicsScreen extends StatelessWidget {
  const VocabTopicsScreen({super.key});

  static const _colors = [
    AppColors.fire,
    AppColors.secondary,
    AppColors.primary,
    AppColors.heart,
    AppColors.gold,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lug\'at mavzular bo\'yicha')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: vocabTopics.length,
        itemBuilder: (context, i) {
          final t = vocabTopics[i];
          final c = _colors[i % _colors.length];
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => _TopicWordsScreen(topic: t, color: c)),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [c.withValues(alpha: 0.18), c.withValues(alpha: 0.05)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: c.withValues(alpha: 0.4), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.emoji, style: const TextStyle(fontSize: 36)),
                  const Spacer(),
                  Text(t.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  Text('${t.words.length} so\'z',
                      style: const TextStyle(
                          color: AppColors.inkLight,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TopicWordsScreen extends StatelessWidget {
  final VocabTopic topic;
  final Color color;
  const _TopicWordsScreen({required this.topic, required this.color});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${topic.emoji}  ${topic.title}')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: topic.words.length,
        itemBuilder: (context, i) {
          final (en, uz) = topic.words[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Text('${i + 1}',
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(en,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                      Text(uz,
                          style: const TextStyle(
                              color: AppColors.inkLight,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
