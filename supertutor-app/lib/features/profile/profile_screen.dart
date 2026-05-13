import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../widgets/duo_button.dart';
import '../auth/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final email = auth.session?.user.email ?? 'Mehmon';
    final initial = (auth.session?.user.email ?? 'M').characters.first.toUpperCase();

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.15),
                    border: Border.all(color: AppColors.primary, width: 3),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(Icons.star_rounded,
                      color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(email,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text('SuperTutor o\'quvchi',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.inkLight)),
          const SizedBox(height: 24),
          if (!auth.isAuthenticated || !AppConfig.supabaseConfigured) ...[
            DuoButton(
              label: 'Kirish / Ro\'yxatdan o\'tish',
              onPressed: () => context.push('/login'),
            ),
          ] else ...[
            const _MenuTile(icon: Icons.notifications_outlined, label: 'Bildirishnomalar'),
            const _MenuTile(icon: Icons.language_outlined, label: 'Til sozlamalari'),
            const _MenuTile(icon: Icons.shield_outlined, label: 'Maxfiylik'),
            const _MenuTile(icon: Icons.help_outline, label: 'Yordam'),
            const SizedBox(height: 24),
            DuoButton(
              label: 'Chiqish',
              variant: DuoButtonVariant.danger,
              icon: Icons.logout,
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).signOut();
              },
            ),
          ],
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'SuperTutor AI · v1.0.0',
              style: TextStyle(color: AppColors.inkLighter, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MenuTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.secondary),
        ),
        title: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.inkLighter),
        onTap: () {},
      ),
    );
  }
}
