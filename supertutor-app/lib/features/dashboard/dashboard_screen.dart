import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config.dart';
import '../auth/auth_controller.dart';
import 'stats_repository.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistika'),
        actions: [
          if (auth.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) context.go('/');
              },
            ),
        ],
      ),
      body: !AppConfig.supabaseConfigured || !auth.isAuthenticated
          ? const _GuestView()
          : const _StatsView(),
    );
  }
}

class _GuestView extends StatelessWidget {
  const _GuestView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bar_chart_outlined, size: 64),
          const SizedBox(height: 12),
          Text('Statistikani ko\'rish uchun ro\'yxatdan o\'ting',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go('/login'),
            child: const Text('Kirish / Ro\'yxatdan o\'tish'),
          ),
        ],
      ),
    );
  }
}

class _StatsView extends ConsumerWidget {
  const _StatsView();

  String _fmtDuration(int seconds) {
    final m = seconds ~/ 60;
    if (m < 60) return '$m min';
    final h = m ~/ 60;
    final rem = m % 60;
    return '${h}h ${rem}m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStats = ref.watch(myStatsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(myStatsProvider.future),
      child: asyncStats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('Statistikani yuklab bo\'lmadi:\n$e',
                textAlign: TextAlign.center),
          ],
        ),
        data: (s) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StatCard(
                title: 'Umumiy o\'qish vaqti',
                value: _fmtDuration(s.totalSeconds)),
            _StatCard(
                title: 'Sessiyalar', value: s.totalSessions.toString()),
            _StatCard(
                title: 'Xabarlar', value: s.totalMessages.toString()),
            _StatCard(
                title: 'Streak', value: '${s.streakDays} kun 🔥'),
            _StatCard(
                title: 'Ingliz tili darajasi', value: s.englishLevel),
            _StatCard(
                title: 'Ingliz tili sessiyalari',
                value: s.englishSessions.toString()),
            _StatCard(
                title: 'Matematika sessiyalari',
                value: s.mathSessions.toString()),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(title),
        trailing:
            Text(value, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}
