import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../widgets/duo_button.dart';
import '../../widgets/haptics.dart';
import '../../widgets/sound_effects.dart';
import '../auth/auth_controller.dart';
import '../currency/currency_controller.dart';
import '../quiz/quiz_models.dart';
import '../quiz/quiz_repository.dart';

/// 60-second flash quiz — as many questions as you can answer.
class QuickPracticeScreen extends ConsumerStatefulWidget {
  final String subject;
  const QuickPracticeScreen({super.key, this.subject = 'english'});

  @override
  ConsumerState<QuickPracticeScreen> createState() =>
      _QuickPracticeScreenState();
}

class _QuickPracticeScreenState extends ConsumerState<QuickPracticeScreen> {
  Timer? _ticker;
  int _seconds = 60;
  int _index = 0;
  int _correct = 0;
  int _wrong = 0;
  bool _loading = true;
  bool _finished = false;
  String? _error;
  Quiz? _quiz;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final q = await ref.read(quizRepositoryProvider).generate(
            subject: widget.subject,
            level: 'A2',
            count: 20,
          );
      setState(() {
        _quiz = q;
        _loading = false;
      });
      _startTimer();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _startTimer() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (_seconds <= 0) {
        t.cancel();
        _finish();
        return;
      }
      setState(() => _seconds -= 1);
    });
  }

  Future<void> _answer(int chosen) async {
    if (_finished || _quiz == null) return;
    final q = _quiz!.questions[_index % _quiz!.questions.length];
    if (chosen == q.correctIndex) {
      Haptics.success();
      SoundEffects.correct();
      setState(() => _correct += 1);
    } else {
      Haptics.error();
      SoundEffects.wrong();
      setState(() => _wrong += 1);
    }
    setState(() => _index += 1);
  }

  Future<void> _finish() async {
    setState(() => _finished = true);
    if (ref.read(authControllerProvider).isAuthenticated && _correct > 0) {
      try {
        await ref
            .read(currencyControllerProvider.notifier)
            .awardXp(_correct, reason: 'quick_practice');
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tezkor mashq (60s)')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _finished
                  ? _buildResult()
                  : _buildQuiz(),
    );
  }

  Widget _buildQuiz() {
    final q = _quiz!.questions[_index % _quiz!.questions.length];
    final pct = _seconds / 60.0;
    final color = _seconds <= 10
        ? AppColors.heart
        : _seconds <= 20
            ? AppColors.gold
            : AppColors.primary;
    return Column(
      children: [
        LinearProgressIndicator(
          value: pct,
          minHeight: 8,
          backgroundColor: AppColors.border,
          valueColor: AlwaysStoppedAnimation(color),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text('⏱ ${_seconds}s',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 20)),
              const Spacer(),
              Text('✓ $_correct',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18)),
              const SizedBox(width: 12),
              Text('✗ $_wrong',
                  style: const TextStyle(
                      color: AppColors.heart,
                      fontWeight: FontWeight.w800,
                      fontSize: 18)),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q.question,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 20),
                ...List.generate(q.options.length, (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _answer(i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.border, width: 2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(String.fromCharCode(65 + i),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(q.options[i],
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15)),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final pct = _correct + _wrong == 0
        ? 0
        : (_correct / (_correct + _wrong) * 100).round();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⚡', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text('$_correct to\'g\'ri',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text('$_correct correct · $_wrong xato · $pct%',
              style: const TextStyle(color: AppColors.inkLight)),
          const SizedBox(height: 8),
          Text('+$_correct XP',
              style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w800,
                  fontSize: 20)),
          const SizedBox(height: 24),
          DuoButton(label: 'Yangi mashq', onPressed: () {
            setState(() {
              _seconds = 60;
              _index = 0;
              _correct = 0;
              _wrong = 0;
              _finished = false;
            });
            _startTimer();
          }),
          const SizedBox(height: 8),
          DuoButton(
            label: 'Tugatish',
            variant: DuoButtonVariant.outline,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
