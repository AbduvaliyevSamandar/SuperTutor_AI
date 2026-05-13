import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../widgets/duo_button.dart';
import '../auth/auth_controller.dart';
import '../currency/currency_controller.dart';
import '../dashboard/stats_repository.dart';
import 'settings_storage.dart';
import 'static_pages.dart';

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
            const SizedBox(height: 20),
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
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Akkaunt o\'chirish: hozircha qo\'lda — elmurodovmaxmud77@gmail.com ga yuboring')),
      );
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
