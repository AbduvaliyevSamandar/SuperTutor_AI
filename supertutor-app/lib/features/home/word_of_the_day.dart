import 'package:flutter/material.dart';

import '../../core/theme.dart';

class WordOfTheDayCard extends StatelessWidget {
  const WordOfTheDayCard({super.key});

  static const _words = [
    ('resilient', 'noun', 'chidamli, tezda tiklanadigan',
        'She is resilient — she bounces back from any setback.'),
    ('curiosity', 'noun', 'qiziquvchanlik',
        'Curiosity is the spark of every great discovery.'),
    ('grateful', 'adj', 'minnatdor',
        'I\'m grateful for the chance to learn every day.'),
    ('endeavor', 'noun', 'urinish, harakat',
        'Learning a language is a lifelong endeavor.'),
    ('eloquent', 'adj', 'ravon gapiruvchi',
        'He gave an eloquent speech that moved everyone.'),
    ('insight', 'noun', 'tushuncha, aniq fahmlash',
        'This book offers deep insights into human nature.'),
    ('ambition', 'noun', 'maqsad, intilish',
        'Her ambition is to become a doctor.'),
    ('perspective', 'noun', 'qarash, nuqtai nazar',
        'Travel changes your perspective on life.'),
    ('genuine', 'adj', 'samimiy, asl',
        'Her smile is always genuine.'),
    ('overcome', 'verb', 'yengib o\'tmoq',
        'She overcame all her fears.'),
    ('dedicate', 'verb', 'bag\'ishlamoq',
        'I dedicate one hour daily to study.'),
    ('reflect', 'verb', 'fikr yuritmoq',
        'Take time to reflect on what you learned today.'),
    ('vivid', 'adj', 'jonli, yorqin',
        'The painting was filled with vivid colors.'),
    ('humble', 'adj', 'kamtar',
        'A truly wise person is always humble.'),
    ('wander', 'verb', 'sayr qilmoq, daydib yurmoq',
        'I love to wander through old streets.'),
    ('quiet', 'adj', 'sokin, tinch',
        'The library is a quiet place to study.'),
    ('passion', 'noun', 'ehtiros, sevgi',
        'Find your passion and follow it.'),
    ('inspire', 'verb', 'ilhomlantirmoq',
        'Great teachers inspire their students.'),
    ('grace', 'noun', 'nazokat, latif',
        'She handled the situation with grace.'),
    ('discover', 'verb', 'kashf qilmoq',
        'You discover new words every day with SuperTutor.'),
  ];

  @override
  Widget build(BuildContext context) {
    final i = DateTime.now().difference(DateTime(2026, 1, 1)).inDays % _words.length;
    final (word, pos, uz, example) = _words[i];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7C4), Color(0xFFFFE066)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldDark.withValues(alpha: 0.5),
            offset: const Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text('📖', style: TextStyle(fontSize: 22)),
              SizedBox(width: 6),
              Text('KUNNING SO\'ZI',
                  style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(word,
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('· $pos',
                    style: const TextStyle(
                        color: AppColors.inkLight,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(uz,
              style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
          const SizedBox(height: 6),
          Text('"$example"',
              style: const TextStyle(
                  color: AppColors.inkLight,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                  height: 1.3)),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.bookmark_border, size: 18),
              label: const Text('Lug\'atda batafsil',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              style: TextButton.styleFrom(foregroundColor: AppColors.ink),
              onPressed: () {
                // Note: Dictionary lookup happens within shell already.
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('"Lug\'at" tabidan "$word" so\'zini qidiring')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedMascot extends StatefulWidget {
  final double size;
  const AnimatedMascot({super.key, this.size = 80});

  @override
  State<AnimatedMascot> createState() => _AnimatedMascotState();
}

class _AnimatedMascotState extends State<AnimatedMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final bob = Curves.easeInOut.transform(_c.value);
        return Transform.translate(
          offset: Offset(0, -bob * 6),
          child: Transform.scale(
            scale: 1 + bob * 0.03,
            child: Image.asset(
              'assets/icon/icon_fg.png',
              width: widget.size,
              height: widget.size,
            ),
          ),
        );
      },
    );
  }
}
