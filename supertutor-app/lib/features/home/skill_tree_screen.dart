import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../widgets/duo_button.dart';
import '../../widgets/haptics.dart';
import '../../widgets/animated_mascot_pro.dart';
import '../auth/auth_controller.dart';
import '../currency/currency_controller.dart';
import '../dashboard/stats_repository.dart';
import '../ielts/ielts_mock_test_screen.dart';
import '../ielts/ielts_speaking_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../podcast/podcast_screen.dart';
import '../practice/quick_practice_screen.dart';
import '../pronunciation/pronunciation_screen.dart';
import '../srs/srs_screen.dart';
import '../stories/stories_screen.dart';
import '../camera/camera_dictionary_screen.dart';
import '../achievements/achievements_screen.dart';
import '../commute/commute_screen.dart';
import 'word_of_the_day.dart';

/// Modern AI-tutor home dashboard (inspired by Brilliant, Babbel, Headspace, Khanmigo).
/// No more snake path — replaced by hero "Today" + continue carousel + subjects grid.
class SkillTreeScreen extends ConsumerWidget {
  const SkillTreeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final statsAsync =
        auth.isAuthenticated ? ref.watch(myStatsProvider) : null;
    final stats = statsAsync?.maybeWhen(data: (s) => s, orElse: () => null);
    final currency = ref.watch(currencyControllerProvider);

    final firstName = _firstName(auth);
    final greeting = _greeting();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        onRefresh: () async {
          if (auth.isAuthenticated) {
            ref.invalidate(myStatsProvider);
            await ref.read(currencyControllerProvider.notifier).refresh();
          }
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _HeaderBar(
                greeting: greeting,
                name: firstName,
                level: stats?.englishLevel ?? 'A1',
                streak: stats?.streakDays ?? 0,
                xp: currency?.xpTotal ?? 0,
                hearts: currency?.hearts ?? 5,
                onHeartsTap: () => _showHeartsModal(context, ref),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _TodayHeroCard(ref: ref, currency: currency),
              ),
            ),
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Davom etish',
                trailing: 'Hammasini',
                onTrailing: () {},
              ),
            ),
            SliverToBoxAdapter(child: _ContinueRow()),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),
            SliverToBoxAdapter(
              child: _SectionHeader(title: 'Mening fanlarim'),
            ),
            SliverToBoxAdapter(
              child: _SubjectsGrid(stats: stats),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),
            SliverToBoxAdapter(
              child: _SectionHeader(title: 'Tezkor mashqlar'),
            ),
            SliverToBoxAdapter(child: _QuickRow()),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),
            SliverToBoxAdapter(
              child: _SectionHeader(title: 'Bugun siz uchun'),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: WordOfTheDayCard(),
              ),
            ),
            SliverToBoxAdapter(child: _DiscoverRow()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  String _firstName(dynamic auth) {
    try {
      final user = auth.session?.user;
      if (user == null) return 'do\'stim';
      final meta = user.userMetadata as Map<String, dynamic>?;
      final display =
          (meta?['display_name'] as String?) ?? (meta?['name'] as String?);
      if (display != null && display.trim().isNotEmpty) {
        return display.trim().split(' ').first;
      }
      final email = user.email as String?;
      if (email != null && email.contains('@')) {
        return email.split('@').first;
      }
    } catch (_) {}
    return 'do\'stim';
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 5) return 'Tunyarim';
    if (h < 12) return 'Xayrli tong';
    if (h < 17) return 'Xayrli kun';
    if (h < 22) return 'Xayrli kech';
    return 'Tunyarim';
  }
}

/// Top header with greeting + 3 stat pills.
class _HeaderBar extends StatelessWidget {
  final String greeting;
  final String name;
  final String level;
  final int streak;
  final int xp;
  final int hearts;
  final VoidCallback onHeartsTap;

  const _HeaderBar({
    required this.greeting,
    required this.name,
    required this.level,
    required this.streak,
    required this.xp,
    required this.hearts,
    required this.onHeartsTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Row(
          children: [
            const SizedBox(
              width: 56,
              height: 56,
              child: AnimatedMascotPro(size: 44),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting, $name 👋',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    'Daraja $level',
                    style: const TextStyle(
                      color: AppColors.inkLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            _Pill(
              icon: Icons.local_fire_department_rounded,
              value: '$streak',
              color: AppColors.fire,
            ),
            const SizedBox(width: 6),
            _Pill(
              icon: Icons.bolt_rounded,
              value: _short(xp),
              color: AppColors.gold,
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: hearts == 0 ? onHeartsTap : null,
              child: _Pill(
                icon: Icons.favorite_rounded,
                value: '$hearts',
                color: AppColors.heart,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _short(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _Pill({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 3),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Hero "Today" card — daily goal progress ring + CTA.
class _TodayHeroCard extends StatelessWidget {
  final WidgetRef ref;
  final dynamic currency;
  const _TodayHeroCard({required this.ref, required this.currency});

  @override
  Widget build(BuildContext context) {
    final earned = (currency?.dailyEarnedXp as int?) ?? 0;
    final target = (currency?.dailyTargetXp as int?) ?? 20;
    final progress = target == 0 ? 0.0 : (earned / target).clamp(0.0, 1.0);
    final reached = progress >= 1.0;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => context.push('/chat/english'),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: reached
                ? const [Color(0xFF22C55E), Color(0xFF16A34A)]
                : const [Color(0xFF6B5BE5), Color(0xFFEC4899)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (reached ? Colors.green : const Color(0xFFEC4899))
                  .withValues(alpha: 0.35),
              offset: const Offset(0, 8),
              blurRadius: 24,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bugungi maqsad',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reached ? 'Maqsad bajarildi! 🎉' : '$earned / $target XP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    reached
                        ? 'Davom eting va seriyani uzaytiring'
                        : 'AI bilan suhbat — eng tez yo\'l',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Boshlash',
                              style: TextStyle(
                                color: Color(0xFF6B5BE5),
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded,
                                color: Color(0xFF6B5BE5), size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _ProgressRing(progress: progress, label: '${(progress * 100).round()}%'),
          ],
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final double progress;
  final String label;
  const _ProgressRing({required this.progress, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section header with optional trailing link.
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback? onTrailing;
  const _SectionHeader({required this.title, this.trailing, this.onTrailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppColors.ink,
              ),
            ),
          ),
          if (trailing != null)
            GestureDetector(
              onTap: onTrailing,
              child: Text(
                trailing!,
                style: const TextStyle(
                  color: AppColors.inkLight,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Horizontal row: 4 prominent "continue" actions.
class _ContinueRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = <_ContinueItem>[
      _ContinueItem('💬', 'Suhbat', 'AI bilan', const Color(0xFF6B5BE5),
          () => context.push('/chat/english')),
      _ContinueItem('⚡', '60s mashq', 'Tezkor', const Color(0xFFEE2C5C), () {
        Haptics.tap();
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const QuickPracticeScreen()));
      }),
      _ContinueItem('🎙', 'Talaffuz', 'AI baho', AppColors.fire, () {
        Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PronunciationScreen()));
      }),
      _ContinueItem('🏆', 'IELTS Mock', 'Band score', AppColors.gold, () {
        Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const IeltsMockTestScreen()));
      }),
    ];
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final it = items[i];
          return SizedBox(
            width: 140,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Haptics.tap();
                it.onTap();
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      it.color.withValues(alpha: 0.95),
                      it.color.withValues(alpha: 0.75),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: it.color.withValues(alpha: 0.35),
                      offset: const Offset(0, 6),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(it.emoji, style: const TextStyle(fontSize: 32)),
                    const Spacer(),
                    Text(
                      it.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      it.subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
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

class _ContinueItem {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  _ContinueItem(this.emoji, this.title, this.subtitle, this.color, this.onTap);
}

/// 2-col grid of subjects with progress.
class _SubjectsGrid extends StatelessWidget {
  final dynamic stats;
  const _SubjectsGrid({required this.stats});

  static const _targetPerSubject = 30;

  int _completed(String key) {
    if (stats == null) return 0;
    switch (key) {
      case 'english':
        return (stats.englishSessions as int?) ?? 0;
      case 'math':
        return (stats.mathSessions as int?) ?? 0;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = <_Subject>[
      _Subject(
        emoji: '🇬🇧',
        title: 'Ingliz tili',
        subtitle: 'Eng mashhur',
        gradient: const [Color(0xFF1CB0F6), Color(0xFF0E80B8)],
        key: 'english',
      ),
      _Subject(
        emoji: '📐',
        title: 'Matematika',
        subtitle: 'AI yordam',
        gradient: const [Color(0xFFFF9600), Color(0xFFE07700)],
        key: 'math',
      ),
      _Subject(
        emoji: '🇷🇺',
        title: 'Rus tili',
        subtitle: 'Kundalik',
        gradient: const [Color(0xFFFF4B4B), Color(0xFFC23030)],
        key: 'russian',
      ),
      _Subject(
        emoji: '🇩🇪',
        title: 'Nemis tili',
        subtitle: 'A1 dan',
        gradient: const [Color(0xFFFFC800), Color(0xFFCFA200)],
        key: 'german',
      ),
      _Subject(
        emoji: '🇹🇷',
        title: 'Turk tili',
        subtitle: 'Oson o\'rganish',
        gradient: const [Color(0xFF58CC02), Color(0xFF3F9402)],
        key: 'turkish',
      ),
      _Subject(
        emoji: '🎓',
        title: 'IELTS prep',
        subtitle: '4 ko\'nikma',
        gradient: const [Color(0xFF6B5BE5), Color(0xFF4A3DC6)],
        key: 'ielts',
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: subjects.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.45,
        ),
        itemBuilder: (_, i) {
          final s = subjects[i];
          final done = _completed(s.key);
          final progress =
              (done / _targetPerSubject).clamp(0.0, 1.0).toDouble();
          return _SubjectCard(subject: s, completed: done, progress: progress);
        },
      ),
    );
  }
}

class _Subject {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final String key;
  const _Subject({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.key,
  });
}

class _SubjectCard extends StatelessWidget {
  final _Subject subject;
  final int completed;
  final double progress;
  const _SubjectCard({
    required this.subject,
    required this.completed,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Haptics.tap();
        if (subject.key == 'ielts') {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const IeltsSpeakingScreen()));
        } else {
          context.push('/chat/${subject.key}');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: subject.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: subject.gradient.last.withValues(alpha: 0.32),
              offset: const Offset(0, 6),
              blurRadius: 14,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(subject.emoji, style: const TextStyle(fontSize: 28)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$completed dars',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              subject.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            Text(
              subject.subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress < 0.04 ? 0.04 : progress,
                minHeight: 5,
                backgroundColor: Colors.white.withValues(alpha: 0.22),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal row of small quick action chips.
class _QuickRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = <_QuickItem>[
      _QuickItem('🔁', 'So\'z\ntakrori', AppColors.gold, () {
        Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SrsReviewScreen()));
      }),
      _QuickItem('📷', 'Kamera\nlug\'at', AppColors.secondary, () {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const CameraDictionaryScreen()));
      }),
      _QuickItem('📖', 'Hikoyalar', AppColors.heart, () {
        Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const StoriesScreen()));
      }),
      _QuickItem('🎙', 'Podcast', AppColors.fire, () {
        Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PodcastScreen()));
      }),
      _QuickItem('🏆', 'Yutuqlar', AppColors.primary, () {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const AchievementsScreen()));
      }),
    ];
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final it = items[i];
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Haptics.tap();
              it.onTap();
            },
            child: Container(
              width: 82,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: it.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: it.color.withValues(alpha: 0.35), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(it.emoji, style: const TextStyle(fontSize: 22)),
                  const Spacer(),
                  Text(
                    it.title,
                    maxLines: 2,
                    style: TextStyle(
                      color: it.color,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuickItem {
  final String emoji;
  final String title;
  final Color color;
  final VoidCallback onTap;
  _QuickItem(this.emoji, this.title, this.color, this.onTap);
}

/// "Discover" horizontal cards.
class _DiscoverRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _DiscoverTile(
            emoji: '🎧',
            title: 'Yo\'lda mashq',
            subtitle: 'Hands-free audio · 10 daq',
            gradient: const [Color(0xFF0EA5E9), Color(0xFF1E40AF)],
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CommuteScreen())),
          ),
          const SizedBox(width: 12),
          _DiscoverTile(
            emoji: '🥇',
            title: 'Leaderboard',
            subtitle: 'O\'zbekistondagi top',
            gradient: const [Color(0xFFFFC800), Color(0xFFFF9600)],
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
          ),
          const SizedBox(width: 12),
          _DiscoverTile(
            emoji: '🎓',
            title: 'IELTS Speaking',
            subtitle: '3 part · AI examiner',
            gradient: const [Color(0xFF6B5BE5), Color(0xFF4A3DC6)],
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const IeltsSpeakingScreen())),
          ),
          const SizedBox(width: 12),
          _DiscoverTile(
            emoji: '📖',
            title: 'Hikoyalar',
            subtitle: 'Lug\'at + tushunish',
            gradient: const [Color(0xFFFF4B4B), Color(0xFFC23030)],
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StoriesScreen())),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

class _DiscoverTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;
  const _DiscoverTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withValues(alpha: 0.32),
              offset: const Offset(0, 6),
              blurRadius: 14,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showHeartsModal(BuildContext context, WidgetRef ref) {
  final currency = ref.read(currencyControllerProvider);
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💔', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 8),
            Text('Yuraklar tugadi',
                style: Theme.of(ctx).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              currency == null
                  ? 'Biroz dam oling'
                  : 'Keyingi yurak ${(currency.nextHeartInSeconds / 60).ceil()} daqiqada.',
              style: const TextStyle(
                  color: AppColors.inkLight, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            DuoButton(
              label: '350 💎 — Yuraklarni to\'ldirish',
              variant: DuoButtonVariant.gold,
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await ref
                    .read(currencyControllerProvider.notifier)
                    .refillHearts();
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gemma yetarli emas')),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
            DuoButton(
              label: 'Yopish',
              variant: DuoButtonVariant.outline,
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    ),
  );
}

