import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme.dart';
import '../../widgets/duo_button.dart';

const String onboardedKey = 'onboarded_v1';

Future<bool> onboardingDone() async {
  final p = await SharedPreferences.getInstance();
  return p.getBool(onboardedKey) ?? false;
}

Future<void> markOnboarded() async {
  final p = await SharedPreferences.getInstance();
  await p.setBool(onboardedKey, true);
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pager = PageController();
  int _page = 0;
  String? _goal;
  String? _level;

  static const _goals = [
    ('🎓', 'IELTS / sertifikat'),
    ('✈️', 'Sayohat'),
    ('💼', 'Ish va karyera'),
    ('🎬', 'Film, kitob, ko\'ngilxushlik'),
  ];

  static const _levels = [
    ('A1', 'Yangi boshlovchi'),
    ('A2', 'Asosiy bilim bor'),
    ('B1', 'O\'rtacha'),
    ('B2', 'Yaxshi'),
    ('C1', 'Yuqori daraja'),
  ];

  bool get _canNext {
    if (_page == 1 && _goal == null) return false;
    if (_page == 2 && _level == null) return false;
    return true;
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await markOnboarded();
    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _ProgressBar(page: _page, total: 4),
            Expanded(
              child: PageView(
                controller: _pager,
                onPageChanged: (i) => setState(() => _page = i),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _WelcomePage(onSkip: _finish),
                  _GoalPage(
                    selected: _goal,
                    onSelect: (g) => setState(() => _goal = g),
                    goals: _goals,
                  ),
                  _LevelPage(
                    selected: _level,
                    onSelect: (l) => setState(() => _level = l),
                    levels: _levels,
                  ),
                  _ReadyPage(goal: _goal, level: _level),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: DuoButton(
                label: _page == 3 ? 'Boshlash 🚀' : 'Davom etish',
                onPressed: !_canNext
                    ? null
                    : () {
                        if (_page == 3) {
                          _finish();
                        } else {
                          _pager.nextPage(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                          );
                        }
                      },
              ),
            ),
            if (_page > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextButton(
                  onPressed: () => _pager.previousPage(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  ),
                  child: const Text('Orqaga',
                      style: TextStyle(
                          color: AppColors.inkLight,
                          fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int page;
  final int total;
  const _ProgressBar({required this.page, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: List.generate(total, (i) {
          final filled = i <= page;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 6,
              margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
              decoration: BoxDecoration(
                color: filled ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  final VoidCallback onSkip;
  const _WelcomePage({required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: TextButton(
              onPressed: onSkip,
              child: const Text('O\'tkazib yuborish',
                  style: TextStyle(
                      color: AppColors.inkLight, fontWeight: FontWeight.w700)),
            ),
          ),
          const Spacer(),
          _MascotCircle(),
          const SizedBox(height: 24),
          Text('Assalomu alaykum! 👋',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text(
            'Men SuperTutor.\nSiz bilan tilni o\'rganamiz — bepul,\nAI bilan suhbat orqali.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.inkLight,
                fontWeight: FontWeight.w600,
                fontSize: 15,
                height: 1.45),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _GoalPage extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;
  final List<(String, String)> goals;
  const _GoalPage({
    required this.selected,
    required this.onSelect,
    required this.goals,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
      children: [
        const SizedBox(height: 24),
        Text('Maqsadingiz nima?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text(
          'Sizga moslashtirib o\'rgataman',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: AppColors.inkLight, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 32),
        ...goals.map((g) {
          final (emoji, label) = g;
          final isSelected = selected == label;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onSelect(label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primary : AppColors.border,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(label,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle,
                          color: AppColors.primary, size: 22),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _LevelPage extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;
  final List<(String, String)> levels;
  const _LevelPage({
    required this.selected,
    required this.onSelect,
    required this.levels,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
      children: [
        const SizedBox(height: 24),
        Text('Joriy darajangiz?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text(
          'Aniq emas bo\'lsa, A1 ni tanlang',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: AppColors.inkLight, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 32),
        ...levels.map((l) {
          final (code, descr) = l;
          final isSelected = selected == code;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onSelect(code),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.secondary.withValues(alpha: 0.1)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.secondary
                        : AppColors.border,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.secondary
                            : AppColors.bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.border, width: 2),
                      ),
                      child: Text(code,
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.ink)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(descr,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _ReadyPage extends StatelessWidget {
  final String? goal;
  final String? level;
  const _ReadyPage({this.goal, this.level});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
      child: Column(
        children: [
          const Spacer(),
          _MascotCircle(),
          const SizedBox(height: 24),
          Text('Hammasi tayyor! 🎉',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 14),
          if (goal != null || level != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  if (goal != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('Maqsad: $goal',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700)),
                    ),
                  if (level != null)
                    Text('Daraja: $level',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          const SizedBox(height: 16),
          const Text(
            'Birinchi suhbatdan boshlaymiz.\nMening AI ovozim bilan gaplashing.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.inkLight, fontWeight: FontWeight.w600),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _MascotCircle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          colors: [
            Color(0xFFE6F9D3),
            Color(0xFFC9F0A1),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Image.asset(
        'assets/icon/icon_fg.png',
        width: 130,
        height: 130,
      ),
    );
  }
}
