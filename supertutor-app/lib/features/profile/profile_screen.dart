import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config.dart';
import '../../core/error_messages.dart';
import '../../core/theme.dart';
import '../../widgets/duo_button.dart';
import '../../core/api_client.dart';
import '../auth/auth_controller.dart';
import '../chat/chat_history_screen.dart';
import '../currency/currency_controller.dart';
import '../dashboard/stats_repository.dart';
import '../feedback/feedback_screen.dart';
import 'settings_storage.dart';
import 'static_pages.dart';

class _DailyXp {
  final String date;
  final int earned;
  final int target;
  _DailyXp({required this.date, required this.earned, required this.target});
}

final _weeklyActivityProvider =
    FutureProvider.autoDispose<List<_DailyXp>>((ref) async {
  final dio = ref.watch(dioProvider);
  final r = await dio.get('/activity/weekly');
  final days = (r.data['days'] as List<dynamic>?) ?? [];
  return days
      .map((e) => _DailyXp(
            date: (e['date'] ?? '') as String,
            earned: (e['earned_xp'] ?? 0) as int,
            target: (e['target_xp'] ?? 20) as int,
          ))
      .toList();
});

({int level, int xpInLevel, int xpForNext}) _xpLevel(int totalXp) {
  // Simple progression: every level needs 100 + 50*(level-1) more XP
  // Level 1: 0..99, Level 2: 100..249, Level 3: 250..449, ...
  var level = 1;
  var consumed = 0;
  while (true) {
    final cost = 100 + 50 * (level - 1);
    if (totalXp < consumed + cost) {
      return (
        level: level,
        xpInLevel: totalXp - consumed,
        xpForNext: cost,
      );
    }
    consumed += cost;
    level += 1;
    if (level > 200) break;
  }
  return (level: level, xpInLevel: 0, xpForNext: 100);
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.session?.user;
    final name = (user?.userMetadata?['name'] as String?)?.trim();
    final email = user?.email ?? 'Mehmon';
    final display = (name == null || name.isEmpty) ? email : name;
    final initial = display.characters.first.toUpperCase();

    final stats = auth.isAuthenticated ? ref.watch(myStatsProvider) : null;
    final currency = ref.watch(currencyControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // Avatar + name
          Center(
            child: Column(
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFFE6F9D3), Color(0xFFC9F0A1)],
                    ),
                    border: Border.all(color: AppColors.primary, width: 3),
                  ),
                  alignment: Alignment.center,
                  child: Text(initial,
                      style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                ),
                const SizedBox(height: 14),
                Text(display,
                    style: Theme.of(context).textTheme.titleLarge),
                if (name != null && name.isNotEmpty)
                  Text(email,
                      style: const TextStyle(
                          color: AppColors.inkLight,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                if (auth.isAuthenticated)
                  TextButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Ismni o\'zgartirish'),
                    onPressed: () => _editName(context, ref, name),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick stats row
          if (auth.isAuthenticated) ...[
            _LevelBar(totalXp: currency?.xpTotal ?? 0),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    icon: '🔥',
                    label: 'Streak',
                    value: '${stats?.maybeWhen(data: (s) => s.streakDays, orElse: () => 0) ?? 0}',
                    color: AppColors.fire,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Stat(
                    icon: '⚡',
                    label: 'XP',
                    value: '${currency?.xpTotal ?? 0}',
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Stat(
                    icon: '💎',
                    label: 'Gemma',
                    value: '${currency?.gems ?? 0}',
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _WeeklyChartCard(),
            const SizedBox(height: 16),
            _SettingsTile(
              icon: Icons.history,
              color: AppColors.secondary,
              label: 'Suhbatlar tarixi',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChatHistoryScreen()),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Account
          _SectionHeader('Akkaunt'),
          if (!auth.isAuthenticated || !AppConfig.supabaseConfigured) ...[
            DuoButton(
              label: 'Kirish / Ro\'yxatdan o\'tish',
              onPressed: () => context.push('/login'),
            ),
            const SizedBox(height: 16),
          ] else
            const SizedBox(height: 0),

          _SettingsTile(
            icon: Icons.notifications_outlined,
            color: AppColors.fire,
            label: 'Bildirishnomalar',
            trailing: _NotifSwitch(),
          ),
          _SettingsTile(
            icon: Icons.volume_up_outlined,
            color: AppColors.gold,
            label: 'Ovoz effektlari',
            trailing: _SoundSwitch(),
          ),
          _SettingsTile(
            icon: Icons.language_outlined,
            color: AppColors.secondary,
            label: 'Interfeys tili',
            trailing: _LangPicker(),
          ),
          _SettingsTile(
            icon: Icons.dark_mode_outlined,
            color: AppColors.ink,
            label: 'Tungi rejim',
            trailing: _DarkSwitch(),
          ),

          const SizedBox(height: 16),
          _SectionHeader('Yordam'),
          _SettingsTile(
            icon: Icons.help_outline,
            color: AppColors.primary,
            label: 'Tez-tez so\'raladigan savollar',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HelpPage()),
            ),
          ),
          _SettingsTile(
            icon: Icons.info_outline,
            color: AppColors.secondary,
            label: 'SuperTutor haqida',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutPage()),
            ),
          ),
          _SettingsTile(
            icon: Icons.shield_outlined,
            color: AppColors.primary,
            label: 'Maxfiylik siyosati',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrivacyPage()),
            ),
          ),
          _SettingsTile(
            icon: Icons.feedback_outlined,
            color: AppColors.fire,
            label: 'Fikr / Xato yuborish',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FeedbackScreen()),
            ),
          ),

          if (auth.isAuthenticated) ...[
            const SizedBox(height: 24),
            DuoButton(
              label: 'Chiqish',
              variant: DuoButtonVariant.danger,
              icon: Icons.logout,
              onPressed: () => _confirmSignOut(context, ref),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _confirmDelete(context, ref),
              child: const Text('Akkauntni o\'chirish',
                  style: TextStyle(
                      color: AppColors.heartDark,
                      fontWeight: FontWeight.w700)),
            ),
          ],
          const SizedBox(height: 16),
          const Center(
            child: Text('SuperTutor AI · v1.0.0',
                style: TextStyle(
                    color: AppColors.inkLighter,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _editName(
      BuildContext context, WidgetRef ref, String? current) async {
    final ctrl = TextEditingController(text: current ?? '');
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ismni kiriting'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Ismingiz'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Bekor qilish')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Saqlash')),
        ],
      ),
    );
    if (newName == null || newName.isEmpty) return;
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'name': newName}),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ism yangilandi')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xato: $e')),
        );
      }
    }
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Chiqasizmi?'),
        content: const Text('Ma\'lumotlaringiz saqlanib qoladi.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Yo\'q')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ha, chiqish')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Akkauntni butunlay o\'chirish?'),
        content: const Text(
          'Barcha ma\'lumotlar (XP, streak, lug\'at, sessiyalar) o\'chiriladi. Bu bekor qilib bo\'lmaydi.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Bekor qilish')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.heart),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('O\'chirish')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(dioProvider).delete('/auth/me');
      await ref.read(authControllerProvider.notifier).signOut();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akkaunt o\'chirildi.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xato: $e')),
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
            color: AppColors.inkLight,
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 0.8),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;
  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 18)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.inkLight,
                  fontWeight: FontWeight.w700,
                  fontSize: 11)),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.color,
    required this.label,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        trailing: trailing ??
            (onTap != null
                ? const Icon(Icons.chevron_right, color: AppColors.inkLighter)
                : null),
      ),
    );
  }
}

class _NotifSwitch extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsControllerProvider);
    return Switch(
      activeThumbColor: AppColors.primary,
      value: s.notifications,
      onChanged: (v) =>
          ref.read(settingsControllerProvider.notifier).setNotifications(v),
    );
  }
}

class _SoundSwitch extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsControllerProvider);
    return Switch(
      activeThumbColor: AppColors.primary,
      value: s.soundsEnabled,
      onChanged: (v) =>
          ref.read(settingsControllerProvider.notifier).setSounds(v),
    );
  }
}

class _LangPicker extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsControllerProvider);
    const flags = {'uz': '🇺🇿', 'en': '🇬🇧', 'ru': '🇷🇺'};
    return DropdownButton<String>(
      value: s.uiLanguage,
      underline: const SizedBox.shrink(),
      items: flags.entries
          .map((e) => DropdownMenuItem(
                value: e.key,
                child: Text('${e.value}  ${e.key.toUpperCase()}'),
              ))
          .toList(),
      onChanged: (v) {
        if (v != null) {
          ref.read(settingsControllerProvider.notifier).setLanguage(v);
        }
      },
    );
  }
}

class _LevelBar extends StatelessWidget {
  final int totalXp;
  const _LevelBar({required this.totalXp});

  @override
  Widget build(BuildContext context) {
    final info = _xpLevel(totalXp);
    final pct = info.xpForNext == 0
        ? 0.0
        : (info.xpInLevel / info.xpForNext).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('Daraja ${info.level}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ),
              const Spacer(),
              Text(
                '${info.xpInLevel} / ${info.xpForNext} XP',
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: AppColors.border,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyChartCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_weeklyActivityProvider);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('14 kunlik faoliyat',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: async.when(
              loading: () => const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (e, _) => Center(
                child: Text(
                  friendlyError(e),
                  style: const TextStyle(
                      color: AppColors.inkLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                ),
              ),
              data: (days) => _BarChart(days: days),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<_DailyXp> days;
  const _BarChart({required this.days});

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const Center(
        child: Text('Hozircha ma\'lumot yo\'q',
            style: TextStyle(
                color: AppColors.inkLight, fontWeight: FontWeight.w600)),
      );
    }
    final maxVal = days
        .map((d) => d.earned > d.target ? d.earned : d.target)
        .fold<int>(0, (a, b) => a > b ? a : b)
        .clamp(20, 99999);

    return LayoutBuilder(builder: (context, c) {
      final barWidth = (c.maxWidth / days.length) - 4;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((d) {
          final earnedH =
              (d.earned / maxVal * 80).clamp(0.0, 80.0).toDouble();
          final reached = d.earned >= d.target && d.target > 0;
          return Container(
            width: barWidth.clamp(6.0, 24.0),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (reached)
                  const Text('✓',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 10)),
                const SizedBox(height: 2),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  height: earnedH > 4 ? earnedH : 4,
                  decoration: BoxDecoration(
                    color: reached
                        ? AppColors.primary
                        : (d.earned > 0
                            ? AppColors.gold
                            : AppColors.border),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }
}

class _DarkSwitch extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsControllerProvider);
    return Switch(
      activeThumbColor: AppColors.primary,
      value: s.darkMode,
      onChanged: (v) =>
          ref.read(settingsControllerProvider.notifier).setDarkMode(v),
    );
  }
}
