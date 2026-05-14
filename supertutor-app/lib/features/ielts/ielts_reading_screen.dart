import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../widgets/duo_button.dart';
import '../../widgets/sound_effects.dart';
import '../auth/auth_controller.dart';
import '../currency/currency_controller.dart';

class IeltsReadingScreen extends ConsumerStatefulWidget {
  const IeltsReadingScreen({super.key});

  @override
  ConsumerState<IeltsReadingScreen> createState() => _IeltsReadingScreenState();
}

class _IeltsReadingScreenState extends ConsumerState<IeltsReadingScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  final Map<int, int> _answers = {};
  Map<String, dynamic>? _result;
  bool _showQuestions = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _data = null;
      _result = null;
      _showQuestions = false;
      _answers.clear();
    });
    try {
      final r = await ref.read(dioProvider).get('/ielts/reading/passage');
      setState(() {
        _data = Map<String, dynamic>.from(r.data);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_data == null) return;
    final qs = (_data!['questions'] as List);
    final ans = List<int>.generate(qs.length, (i) => _answers[i] ?? -1);
    try {
      final r = await ref.read(dioProvider).post('/ielts/reading/check',
          data: {'questions': qs, 'answers': ans});
      final result = Map<String, dynamic>.from(r.data);
      setState(() => _result = result);
      final pct = result['percentage'] as int? ?? 0;
      if (pct >= 60) {
        SoundEffects.correct();
      } else {
        SoundEffects.wrong();
      }
      if (ref.read(authControllerProvider).isAuthenticated) {
        await ref
            .read(currencyControllerProvider.notifier)
            .awardXp(15, reason: 'ielts_reading');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IELTS Reading'),
        actions: [
          if (_data != null && _result == null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _load,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_error!, textAlign: TextAlign.center),
                ))
              : _result != null
                  ? _buildResult()
                  : _showQuestions
                      ? _buildQuestions()
                      : _buildPassage(),
    );
  }

  Widget _buildPassage() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(_data!['title'] ?? '',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              Text(_data!['passage'] ?? '',
                  style: const TextStyle(
                      fontSize: 15, height: 1.6, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: DuoButton(
              label: 'Savollar →',
              onPressed: () => setState(() => _showQuestions = true),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestions() {
    final qs = (_data!['questions'] as List);
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: qs.length,
            itemBuilder: (context, i) {
              final q = Map<String, dynamic>.from(qs[i]);
              final opts = List<String>.from(q['options'] ?? const []);
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${i + 1}. ${q['question']}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    ...List.generate(opts.length, (oi) {
                      final sel = _answers[i] == oi;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => setState(() => _answers[i] = oi),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppColors.primary.withValues(alpha: 0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: sel
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(String.fromCharCode(65 + oi),
                                    style: TextStyle(
                                        color: sel
                                            ? AppColors.primary
                                            : AppColors.inkLight,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(width: 10),
                                Expanded(child: Text(opts[oi])),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DuoButton(
                    label: 'Matnga qaytish',
                    variant: DuoButtonVariant.outline,
                    onPressed: () => setState(() => _showQuestions = false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DuoButton(
                    label: 'Tugatish',
                    onPressed: _answers.length == qs.length ? _submit : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final pct = _result!['percentage'] as int? ?? 0;
    final band = (_result!['band'] as num?)?.toDouble() ?? 0;
    final c = band >= 6.5
        ? AppColors.primary
        : band >= 5.0
            ? AppColors.gold
            : AppColors.heart;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [c.withValues(alpha: 0.9), c],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Text('📖', style: TextStyle(fontSize: 48)),
              Text(band.toStringAsFixed(1),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 60,
                      fontWeight: FontWeight.w800,
                      height: 1)),
              const Text('Reading Band',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                  '${_result!['score']}/${_result!['total']} to\'g\'ri · $pct%',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('+15 XP',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        DuoButton(label: 'Yangi matn', onPressed: _load),
        const SizedBox(height: 8),
        DuoButton(
          label: 'Tugatish',
          variant: DuoButtonVariant.outline,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
