import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../widgets/duo_button.dart';
import '../../widgets/sound_effects.dart';
import '../auth/auth_controller.dart';
import '../currency/currency_controller.dart';

class SrsReviewScreen extends ConsumerStatefulWidget {
  const SrsReviewScreen({super.key});

  @override
  ConsumerState<SrsReviewScreen> createState() => _SrsReviewScreenState();
}

class _SrsReviewScreenState extends ConsumerState<SrsReviewScreen> {
  List<dynamic> _words = const [];
  int _index = 0;
  bool _revealed = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!ref.read(authControllerProvider).isAuthenticated) {
      setState(() {
        _loading = false;
        _error = 'Saqlangan so\'zlarni takrorlash uchun kiring.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await ref.read(dioProvider).get('/srs/due');
      setState(() {
        _words = (r.data as List?) ?? const [];
        _index = 0;
        _revealed = false;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _generatePersonalized() async {
    setState(() => _loading = true);
    try {
      final r = await ref.read(dioProvider).post(
        '/vocab/personalized/generate',
        data: {'language': 'english', 'level': 'A2', 'n_words': 50},
      );
      final inserted = (r.data['inserted'] as int?) ?? 0;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$inserted ta yangi so\'z qo\'shildi')),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Yaratib bo\'lmadi: $e';
        });
      }
    }
  }

  Future<void> _rate(int rating) async {
    if (_index >= _words.length) return;
    final id = _words[_index]['id'] as String;
    try {
      await ref.read(dioProvider).post('/srs/review',
          data: {'word_id': id, 'rating': rating});
    } catch (_) {}
    if (rating >= 3) {
      SoundEffects.correct();
      if (ref.read(authControllerProvider).isAuthenticated) {
        try {
          await ref.read(currencyControllerProvider.notifier).awardXp(1, reason: 'srs');
        } catch (_) {}
      }
    } else {
      SoundEffects.wrong();
    }
    setState(() {
      _index += 1;
      _revealed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('So\'z takrori')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_error!, textAlign: TextAlign.center),
                ))
              : _words.isEmpty
                  ? _EmptyState(onGenerate: _generatePersonalized)
                  : _index >= _words.length
                      ? _DoneState(reviewed: _words.length, onAgain: _load)
                      : _buildCard(),
    );
  }

  Widget _buildCard() {
    final w = Map<String, dynamic>.from(_words[_index]);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: (_index + (_revealed ? 0.5 : 0)) / _words.length,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            minHeight: 6,
          ),
          const SizedBox(height: 8),
          Text('${_index + 1} / ${_words.length}',
              style: const TextStyle(
                  color: AppColors.inkLight, fontWeight: FontWeight.w600)),
          const SizedBox(height: 28),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(w['word'] ?? '',
                      style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  if (_revealed) ...[
                    Text(w['translation_uz'] ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 20,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    Text(w['definition'] ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.inkLight,
                            fontStyle: FontStyle.italic)),
                  ] else
                    const Text('Ma\'nosini eslang...',
                        style: TextStyle(
                            color: AppColors.inkLighter,
                            fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!_revealed)
            DuoButton(
              label: 'Ko\'rsatish',
              variant: DuoButtonVariant.secondary,
              onPressed: () => setState(() => _revealed = true),
            )
          else
            Row(
              children: [
                Expanded(
                  child: DuoButton(
                    label: 'Yo\'q',
                    variant: DuoButtonVariant.danger,
                    onPressed: () => _rate(1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DuoButton(
                    label: 'Qiyin',
                    variant: DuoButtonVariant.gold,
                    onPressed: () => _rate(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DuoButton(
                    label: 'OK',
                    onPressed: () => _rate(3),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DuoButton(
                    label: 'Oson',
                    variant: DuoButtonVariant.secondary,
                    onPressed: () => _rate(4),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onGenerate;
  const _EmptyState({required this.onGenerate});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📚', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            const Text(
              'Hozircha takrorlanadigan so\'z yo\'q.\nLug\'atdan saqlang yoki shaxsiy boshlang\'ich to\'plamni AI tuzib bersin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.inkLight),
            ),
            const SizedBox(height: 16),
            DuoButton(
              label: '✨ AI boshlang\'ich to\'plam yarat',
              variant: DuoButtonVariant.primary,
              onPressed: onGenerate,
            ),
          ],
        ),
      ),
    );
  }
}

class _DoneState extends StatelessWidget {
  final int reviewed;
  final VoidCallback onAgain;
  const _DoneState({required this.reviewed, required this.onAgain});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 8),
          Text('$reviewed ta so\'z takrorlandi',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          DuoButton(label: 'Bosh ekran', onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}
