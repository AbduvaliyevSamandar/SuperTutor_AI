import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../widgets/duo_button.dart';

final myCodeProvider = FutureProvider<String>((ref) async {
  final r = await ref.read(dioProvider).get('/friends/me');
  return r.data['friend_code'] as String;
});

final friendsListProvider = FutureProvider<List<dynamic>>((ref) async {
  final r = await ref.read(dioProvider).get('/friends/list');
  return (r.data as List?) ?? const [];
});

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = ref.watch(myCodeProvider);
    final list = ref.watch(friendsListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Do\'stlar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          code.when(
            loading: () => const SizedBox(
                height: 80, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox.shrink(),
            data: (c) => _MyCodeCard(code: c),
          ),
          const SizedBox(height: 16),
          DuoButton(
            label: 'Do\'st qo\'shish',
            icon: Icons.person_add,
            onPressed: () => _showAddDialog(context, ref),
          ),
          const SizedBox(height: 20),
          Text('Do\'stlar leaderboard',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          list.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Xato: $e'),
            data: (items) {
              if (items.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      'Hozircha do\'stlar yo\'q.\nDo\'stingizning kodini kiriting.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.inkLight),
                    ),
                  ),
                );
              }
              return Column(
                children: List.generate(items.length, (i) {
                  final row = Map<String, dynamic>.from(items[i]);
                  final medal = i == 0
                      ? '🥇'
                      : i == 1
                          ? '🥈'
                          : i == 2
                              ? '🥉'
                              : '${i + 1}';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          child: Text(medal,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(row['display_name'] ?? 'Do\'st',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                        ),
                        Text('🔥 ${row['streak_days']}',
                            style: const TextStyle(
                                color: AppColors.fire,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(width: 10),
                        Text('${row['xp_total']} XP',
                            style: const TextStyle(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final err = ValueNotifier<String?>(null);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Do\'st kodini kiriting'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              decoration: const InputDecoration(
                hintText: 'ABC123',
                counterText: '',
              ),
            ),
            ValueListenableBuilder<String?>(
              valueListenable: err,
              builder: (_, e, __) => e == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(e,
                          style: const TextStyle(color: AppColors.heart)),
                    ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Bekor qilish')),
          FilledButton(
            onPressed: () async {
              try {
                await ref.read(dioProvider).post('/friends/add',
                    data: {'friend_code': ctrl.text.trim()});
                if (ctx.mounted) Navigator.pop(ctx);
                ref.invalidate(friendsListProvider);
              } catch (e) {
                err.value = e.toString().split('detail:').last;
              }
            },
            child: const Text('Qo\'shish'),
          ),
        ],
      ),
    );
  }
}

class _MyCodeCard extends StatelessWidget {
  final String code;
  const _MyCodeCard({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF3FA800)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sizning kodingiz',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(code,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 30,
                        letterSpacing: 4)),
              ),
              IconButton(
                tooltip: 'Nusxa olish',
                icon: const Icon(Icons.copy, color: Colors.white),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kod nusxalandi')),
                    );
                  }
                },
              ),
            ],
          ),
          const Text('Do\'stlaringizga shu kodni yuboring',
              style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
        ],
      ),
    );
  }
}
