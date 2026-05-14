import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../widgets/duo_button.dart';
import '../auth/auth_controller.dart';
import '../currency/currency_controller.dart';
import 'ielts_listening_screen.dart';
import 'ielts_reading_screen.dart';
import 'ielts_speaking_screen.dart';
import 'ielts_writing_screen.dart';

class IeltsMockTestScreen extends ConsumerStatefulWidget {
  const IeltsMockTestScreen({super.key});

  @override
  ConsumerState<IeltsMockTestScreen> createState() =>
      _IeltsMockTestScreenState();
}

class _IeltsMockTestScreenState extends ConsumerState<IeltsMockTestScreen> {
  final Map<String, double> _bands = {};
  Map<String, dynamic>? _result;

  static const _order = [
    ('listening', '🎧', 'Listening', '~10 daqiqa'),
    ('reading', '📖', 'Reading', '~20 daqiqa'),
    ('writing', '✍️', 'Writing', '40 daqiqa'),
    ('speaking', '🗣', 'Speaking', '~15 daqiqa'),
  ];

  Future<void> _open(String section) async {
    Widget screen;
    switch (section) {
      case 'listening':
        screen = const IeltsListeningScreen();
        break;
      case 'reading':
        screen = const IeltsReadingScreen();
        break;
      case 'writing':
        screen = const IeltsWritingScreen();
        break;
      case 'speaking':
        screen = const IeltsSpeakingScreen();
        break;
      default:
        return;
    }
    // After completing the section, prompt user to enter band manually
    // (because each section flow has its own result screen we cannot intercept
    // cleanly; this keeps the mock test data simple).
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
    if (!mounted) return;
    final band = await _askBand(context, section);
    if (band != null) {
      setState(() => _bands[section] = band);
    }
  }

  Future<double?> _askBand(BuildContext context, String section) async {
    double? picked;
    return showDialog<double>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSB) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('${section[0].toUpperCase()}${section.substring(1)} band'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Olgan band scoreni tanlang'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: [
                  for (final b in [4.0, 4.5, 5.0, 5.5, 6.0, 6.5, 7.0, 7.5, 8.0, 8.5, 9.0])
                    ChoiceChip(
                      label: Text(b.toStringAsFixed(1)),
                      selected: picked == b,
                      onSelected: (_) => setSB(() => picked = b),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('Bekor qilish')),
            FilledButton(
                onPressed: picked == null
                    ? null
                    : () => Navigator.pop(ctx, picked),
                child: const Text('Saqlash')),
          ],
        );
      }),
    );
  }

  Future<void> _submit() async {
    if (_bands.length < 4) return;
    final results = _bands.entries
        .map((e) => {'section': e.key, 'band': e.value})
        .toList();
    try {
      final r = await ref
          .read(dioProvider)
          .post('/ielts/mock/score', data: {'results': results});
      setState(() => _result = Map<String, dynamic>.from(r.data));
      if (ref.read(authControllerProvider).isAuthenticated) {
        await ref
            .read(currencyControllerProvider.notifier)
            .awardXp(50, reason: 'ielts_mock');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xato: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) return _buildResult();
    return Scaffold(
      appBar: AppBar(title: const Text('IELTS Mock Test')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B5BE5), Color(0xFF4A3DC6)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🎓 To\'liq IELTS Mock Test',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18)),
                SizedBox(height: 4),
                Text(
                  '4 ta bo\'limni ketma-ket bajaring. Yakuniy band score chiqadi.',
                  style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._order.map((s) {
            final (key, emoji, title, dur) = s;
            final band = _bands[key];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _open(key),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: band != null
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: band != null
                          ? AppColors.primary
                          : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16)),
                            Text(dur,
                                style: const TextStyle(
                                    color: AppColors.inkLight,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      if (band != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(band.toStringAsFixed(1),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800)),
                        )
                      else
                        const Icon(Icons.arrow_forward_rounded,
                            color: AppColors.inkLight),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          DuoButton(
            label: _bands.length < 4
                ? '${_bands.length}/4 bo\'lim tugadi'
                : 'Yakuniy band scoreni hisoblash',
            onPressed: _bands.length < 4 ? null : _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final r = _result!;
    final overall = (r['overall'] as num).toDouble();
    final cefr = r['cefr'] as String;
    final c = overall >= 7
        ? AppColors.primary
        : overall >= 5.5
            ? AppColors.gold
            : AppColors.heart;
    return Scaffold(
      appBar: AppBar(title: const Text('IELTS Mock Test natijasi')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [c.withValues(alpha: 0.9), c],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: c.withValues(alpha: 0.5),
                  offset: const Offset(0, 6),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                const Text('🎓', style: TextStyle(fontSize: 64)),
                Text(overall.toStringAsFixed(1),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 72,
                        fontWeight: FontWeight.w800,
                        height: 1)),
                const Text('Overall Band',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('CEFR: $cefr',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 12),
                const Text('+50 XP',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final section in ['listening', 'reading', 'writing', 'speaking'])
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      section[0].toUpperCase() + section.substring(1),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                  Text(
                    ((r[section] as num?) ?? 0).toStringAsFixed(1),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppColors.primary),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          DuoButton(label: 'Tugatish', onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}
