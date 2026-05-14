import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../widgets/shimmer_box.dart';

final wordOfDayProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final r = await ref.read(dioProvider).get('/word-of-day');
  return Map<String, dynamic>.from(r.data);
});

class WordOfTheDayCard extends ConsumerWidget {
  const WordOfTheDayCard({super.key});

  // Fallback list if backend unavailable (offline / slow first call).
  static const _fallback = [
    ('resilient', 'adj', 'chidamli',
        'She is resilient — she bounces back from any setback.'),
    ('curiosity', 'noun', 'qiziquvchanlik',
        'Curiosity is the spark of every great discovery.'),
    ('grateful', 'adj', 'minnatdor',
        'I\'m grateful for the chance to learn every day.'),
    ('endeavor', 'noun', 'urinish',
        'Learning a language is a lifelong endeavor.'),
    ('eloquent', 'adj', 'ravon gapiruvchi',
        'He gave an eloquent speech.'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(wordOfDayProvider);
    return async.when(
      loading: () => _wrap(child: const _SkeletonWord()),
      error: (_, _) {
        final i =
            DateTime.now().difference(DateTime(2026, 1, 1)).inDays % _fallback.length;
        final (w, p, uz, ex) = _fallback[i];
        return _wrap(
          child: _Body(
              word: w,
              partOfSpeech: p,
              uz: uz,
              definition: null,
              example: ex),
        );
      },
      data: (data) => _wrap(
        child: _Body(
          word: data['word'] ?? '',
          partOfSpeech: data['part_of_speech'] ?? '',
          uz: data['translation_uz'] ?? '',
          definition: data['definition_en'],
          example: data['example'] ?? '',
        ),
      ),
    );
  }

  Widget _wrap({required Widget child}) {
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
      child: child,
    );
  }
}

class _SkeletonWord extends StatelessWidget {
  const _SkeletonWord();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Row(children: [
          Text('📖', style: TextStyle(fontSize: 22)),
          SizedBox(width: 6),
          Text('KUNNING SO\'ZI',
              style: TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  fontSize: 11)),
        ]),
        SizedBox(height: 10),
        ShimmerBox(height: 26, width: 140),
        SizedBox(height: 8),
        ShimmerBox(height: 16, width: 200),
        SizedBox(height: 6),
        ShimmerBox(height: 14, width: 280),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  final String word;
  final String partOfSpeech;
  final String uz;
  final String? definition;
  final String example;
  const _Body({
    required this.word,
    required this.partOfSpeech,
    required this.uz,
    required this.definition,
    required this.example,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
            Flexible(
              child: Text(word,
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 6),
            if (partOfSpeech.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('· $partOfSpeech',
                    style: const TextStyle(
                        color: AppColors.inkLight,
                        fontWeight: FontWeight.w600)),
              ),
          ],
        ),
        const SizedBox(height: 4),
        if (uz.isNotEmpty)
          Text(uz,
              style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
        if (definition != null && definition!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(definition!,
              style: const TextStyle(
                  color: AppColors.inkLight,
                  fontWeight: FontWeight.w500,
                  fontSize: 13)),
        ],
        if (example.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('"$example"',
              style: const TextStyle(
                  color: AppColors.inkLight,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                  height: 1.3)),
        ],
      ],
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
