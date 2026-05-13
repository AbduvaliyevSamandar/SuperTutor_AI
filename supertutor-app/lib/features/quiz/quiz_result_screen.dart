import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/duo_button.dart';
import '../../widgets/sound_effects.dart';
import 'quiz_models.dart';

class QuizResultScreen extends StatefulWidget {
  final QuizResultSummary result;
  final int xpEarned;
  final bool dailyGoalReached;

  const QuizResultScreen({
    super.key,
    required this.result,
    this.xpEarned = 0,
    this.dailyGoalReached = false,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.result.percentage >= 80) {
        _confetti.play();
        SoundEffects.correct();
      } else if (widget.result.percentage >= 50) {
        SoundEffects.correct();
      } else {
        SoundEffects.wrong();
      }
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  QuizResultSummary get result => widget.result;

  Color _scoreColor() {
    if (result.percentage >= 80) return AppColors.primary;
    if (result.percentage >= 50) return AppColors.gold;
    return AppColors.heart;
  }

  String _emoji() {
    if (result.percentage >= 80) return '🎉';
    if (result.percentage >= 50) return '👍';
    return '💪';
  }

  String _message() {
    if (result.percentage >= 80) return 'A\'lo natija! Davom eting.';
    if (result.percentage >= 50) return 'Yaxshi, lekin yaxshilash mumkin.';
    return 'Bu mavzuni qaytadan ko\'rib chiqing.';
  }

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Natija'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirection: math.pi / 2,
              maxBlastForce: 20,
              minBlastForce: 8,
              emissionFrequency: 0.04,
              numberOfParticles: 25,
              gravity: 0.25,
              colors: const [
                AppColors.primary,
                AppColors.gold,
                AppColors.secondary,
                AppColors.heart,
              ],
            ),
          ),
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withValues(alpha: 0.9), color],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  offset: const Offset(0, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                Text(_emoji(), style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 8),
                Text(
                  '${result.percentage}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 56,
                    height: 1,
                  ),
                ),
                Text(
                  '${result.score} / ${result.total} to\'g\'ri',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _message(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (widget.xpEarned > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '+${widget.xpEarned} XP',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16),
                    ),
                  ),
                ],
                if (widget.dailyGoalReached) ...[
                  const SizedBox(height: 8),
                  const Text(
                    '🎯 Kunlik maqsadga erishdingiz! +5 💎',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Javoblar tahlili',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...result.results.asMap().entries.map((e) {
            final i = e.key;
            final r = e.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: r.correct
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : AppColors.heart.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: r.correct
                              ? AppColors.primary
                              : AppColors.heart,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          r.correct ? Icons.check : Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Savol ${i + 1}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(r.question,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  _AnswerRow(
                    label: 'Sizning javob',
                    value: r.userAnswer,
                    color: r.correct ? AppColors.primary : AppColors.heart,
                  ),
                  if (!r.correct) ...[
                    const SizedBox(height: 4),
                    _AnswerRow(
                      label: 'To\'g\'ri javob',
                      value: r.correctAnswer,
                      color: AppColors.primary,
                    ),
                  ],
                  if (r.explanation.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb_outline,
                              color: AppColors.secondary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              r.explanation,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          if (result.weakTopics.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.fire.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Text('🎯', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 8),
                      Text('E\'tibor bering',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...result.weakTopics.map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $t',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.ink)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          DuoButton(
            label: 'Tugatish',
            onPressed: () => Navigator.of(context).pop(),
          ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnswerRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _AnswerRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              color: AppColors.inkLight,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
