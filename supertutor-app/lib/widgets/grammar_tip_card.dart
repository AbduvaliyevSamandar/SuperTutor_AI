import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../features/grammar/grammar_data.dart';

/// Compact 1-screen grammar reminder shown before a lesson/story.
/// LingoDeer pattern: explicit grammar primer, then drill.
///
/// Pass [tipCode] matching an entry in [grammarLessons]; if null, picks a
/// rotating tip based on the current weekday.
class GrammarTipCard extends StatelessWidget {
  final String? tipCode;
  const GrammarTipCard({super.key, this.tipCode});

  GrammarLesson? get _lesson {
    if (grammarLessons.isEmpty) return null;
    if (tipCode != null) {
      for (final g in grammarLessons) {
        if (g.code == tipCode) return g;
      }
    }
    final idx = DateTime.now().weekday % grammarLessons.length;
    return grammarLessons[idx];
  }

  @override
  Widget build(BuildContext context) {
    final g = _lesson;
    if (g == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE0F2FE), Color(0xFFDBEAFE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF60A5FA).withValues(alpha: 0.4), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(g.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 6),
              const Text(
                'GRAMATIK ESLATMA',
                style: TextStyle(
                  color: Color(0xFF1E40AF),
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            g.title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            g.summary,
            style: const TextStyle(
              color: AppColors.inkLight,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          if (g.examples.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...g.examples.take(2).map((e) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '• $e',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF1E3A8A),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
