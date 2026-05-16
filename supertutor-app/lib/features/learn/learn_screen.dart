import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../achievements/achievements_screen.dart';
import '../exercises/cloze_screen.dart';
import '../exercises/listening_screen.dart';
import '../camera/camera_dictionary_screen.dart';
import '../friends/friends_screen.dart';
import '../grammar/grammar_screen.dart';
import '../podcast/podcast_screen.dart';
import '../practice/quick_practice_screen.dart';
import '../vocab/vocab_topics_screen.dart';
import '../ielts/ielts_listening_screen.dart';
import '../ielts/ielts_mock_test_screen.dart';
import '../ielts/ielts_reading_screen.dart';
import '../ielts/ielts_speaking_screen.dart';
import '../ielts/ielts_writing_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../pronunciation/pronunciation_screen.dart';
import '../quiz/quiz_screen.dart';
import '../scenarios/scenarios.dart';
import '../srs/srs_screen.dart';
import '../stories/stories_screen.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Darslar')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: _QuickLink(
                  emoji: '🏆',
                  label: 'Yutuqlar',
                  color: AppColors.gold,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const AchievementsScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickLink(
                  emoji: '🥇',
                  label: 'Leaderboard',
                  color: AppColors.fire,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const LeaderboardScreen()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _QuickLink(
            emoji: '👥',
            label: 'Do\'stlar',
            color: AppColors.primary,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FriendsScreen()),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const QuickPracticeScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFEE2C5C)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEE2C5C).withValues(alpha: 0.5),
                    offset: const Offset(0, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text('⚡', style: TextStyle(fontSize: 36)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('60s tezkor mashq',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16)),
                        Text('Ko\'p javob ber — ko\'p XP',
                            style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.play_arrow_rounded, color: Colors.white),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Mashqlar',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ExerciseTile(
                  emoji: '🎧',
                  title: 'Tinglash',
                  subtitle: 'Audio → matn',
                  color: AppColors.secondary,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const ListeningExerciseScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ExerciseTile(
                  emoji: '📝',
                  title: 'Gap to\'ldirish',
                  subtitle: 'Cloze',
                  color: AppColors.primary,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const ClozeExerciseScreen()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ExerciseTile(
                  emoji: '🎙️',
                  title: 'Talaffuz',
                  subtitle: 'Aniq aytib bering',
                  color: AppColors.fire,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const PronunciationScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ExerciseTile(
                  emoji: '🔁',
                  title: 'So\'z takrori',
                  subtitle: 'SRS - kunlik',
                  color: AppColors.gold,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const SrsReviewScreen()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ExerciseTile(
                  emoji: '📷',
                  title: 'Kamera lug\'at',
                  subtitle: 'Suratga ol, nom o\'rgan',
                  color: AppColors.secondary,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const CameraDictionaryScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ExerciseTile(
                  emoji: '📚',
                  title: 'Mavzular lug\'ati',
                  subtitle: '8 mavzu',
                  color: AppColors.primary,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const VocabTopicsScreen()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ExerciseTile(
                  emoji: '🎙️',
                  title: 'Kunlik podcast',
                  subtitle: '~5 daq tinglash',
                  color: AppColors.fire,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PodcastScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ExerciseTile(
                  emoji: '📖',
                  title: 'Hikoyalar',
                  subtitle: 'O\'qib tushunish',
                  color: AppColors.heart,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const StoriesScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ExerciseTile(
                  emoji: '📐',
                  title: 'Grammatika',
                  subtitle: '17 mavzu',
                  color: AppColors.secondary,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const GrammarListScreen()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _IeltsBanner(
            emoji: '🏆',
            title: 'IELTS Mock Test (to\'liq)',
            subtitle: '4 ta bo\'lim · umumiy band score',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const IeltsMockTestScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _IeltsBanner(
            emoji: '🎓',
            title: 'IELTS Speaking simulyator',
            subtitle: '3 part · AI examiner · Band score',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const IeltsSpeakingScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _IeltsBanner(
            emoji: '✍️',
            title: 'IELTS Writing Task 2',
            subtitle: '40 daq · essay · band feedback',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const IeltsWritingScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _IeltsBanner(
            emoji: '📖',
            title: 'IELTS Reading',
            subtitle: 'Matn + 7 savol · band score',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const IeltsReadingScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _IeltsBanner(
            emoji: '🎧',
            title: 'IELTS Listening',
            subtitle: 'Audio + 5 savol',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const IeltsListeningScreen()),
            ),
          ),

          const SizedBox(height: 24),
          Text('Tezkor test',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text(
            'AI 5 ta savol tuzadi, javob bering — natija tahlil bilan.',
            style: TextStyle(
                color: AppColors.inkLight, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
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
          Text('Suhbat ssenariylari',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text(
            'Real hayotdagi vaziyatlarda AI bilan suhbat',
            style: TextStyle(
                color: AppColors.inkLight, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.95,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: scenarios.length,
            itemBuilder: (context, i) {
              final s = scenarios[i];
              return _ScenarioCard(
                scenario: s,
                onTap: () {
                  final params = <String, String>{
                    'seed': s.openingUserMessage,
                  };
                  if (s.role.isNotEmpty) params['role'] = s.role;
                  if (s.goal.isNotEmpty) params['goal'] = s.goal;
                  final qs = params.entries
                      .map((e) =>
                          '${e.key}=${Uri.encodeQueryComponent(e.value)}')
                      .join('&');
                  context.push('/chat/${s.subject}?$qs');
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _IeltsBanner extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _IeltsBanner({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6B5BE5), Color(0xFF4A3DC6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A3DC6).withValues(alpha: 0.5),
              offset: const Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ExerciseTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 6),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 14)),
            Text(subtitle,
                style: const TextStyle(
                    color: AppColors.inkLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickLink({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 2),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15)),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  final Scenario scenario;
  final VoidCallback onTap;
  const _ScenarioCard({required this.scenario, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scenario.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: scenario.color.withValues(alpha: 0.4), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(scenario.emoji, style: const TextStyle(fontSize: 32)),
            const Spacer(),
            Text(scenario.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 14, height: 1.2)),
            const SizedBox(height: 4),
            Text(
              scenario.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.inkLight,
                fontWeight: FontWeight.w500,
                fontSize: 11,
                height: 1.25,
              ),
            ),
          ],
        ),
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
