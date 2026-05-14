import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme.dart';
import '../../widgets/haptics.dart';
import '../../widgets/sound_effects.dart';
import '../currency/currency_controller.dart';
import '../dashboard/stats_repository.dart';
import 'achievement_specs.dart';

class AchievementWatcher extends ConsumerStatefulWidget {
  final Widget child;
  const AchievementWatcher({super.key, required this.child});

  @override
  ConsumerState<AchievementWatcher> createState() => _AchievementWatcherState();
}

class _AchievementWatcherState extends ConsumerState<AchievementWatcher> {
  Set<String>? _seen;

  Future<Set<String>> _loadSeen() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList('seen_achievements') ?? const []).toSet();
  }

  Future<void> _saveSeen(Set<String> seen) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList('seen_achievements', seen.toList());
  }

  AchievementStats _build() {
    final stats = ref.read(myStatsProvider).maybeWhen(
          data: (s) => s,
          orElse: () => null,
        );
    final currency = ref.read(currencyControllerProvider);
    return AchievementStats(
      xpTotal: currency?.xpTotal ?? 0,
      streakDays: stats?.streakDays ?? 0,
      totalSessions: stats?.totalSessions ?? 0,
      totalMessages: stats?.totalMessages ?? 0,
      englishSessions: stats?.englishSessions ?? 0,
      mathSessions: stats?.mathSessions ?? 0,
    );
  }

  Future<void> _check() async {
    _seen ??= await _loadSeen();
    final stats = _build();
    final earned = achievements.where((a) => a.check(stats)).toList();
    final newOnes = earned.where((a) => !_seen!.contains(a.code)).toList();
    if (newOnes.isEmpty) return;

    for (final a in newOnes) {
      _seen!.add(a.code);
      if (mounted) _showUnlocked(a);
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    await _saveSeen(_seen!);
  }

  void _showUnlocked(AchievementSpec a) {
    Haptics.success();
    SoundEffects.correct();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: a.color,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            Text(a.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Yangi yutuq!',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13)),
                  Text(a.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(myStatsProvider, (_, _) => _check());
    ref.listen(currencyControllerProvider, (_, _) => _check());
    return widget.child;
  }
}
