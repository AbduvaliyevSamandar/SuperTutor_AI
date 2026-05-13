import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../widgets/duo_button.dart';
import 'quiz_models.dart';
import 'quiz_repository.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String subject;
  final String level;

  const QuizScreen({super.key, required this.subject, this.level = 'A2'});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  Quiz? _quiz;
  int _current = 0;
  final Map<String, int> _answers = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final q = await ref.read(quizRepositoryProvider).generate(
            subject: widget.subject,
            level: widget.level,
            count: 5,
          );
      setState(() => _quiz = q);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_quiz == null) return;
    setState(() => _loading = true);
    try {
      final result = await ref
          .read(quizRepositoryProvider)
          .submit(quiz: _quiz!, answers: _answers);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(result: result),
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Test')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.heart, size: 48),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              DuoButton(label: 'Qayta urinish', onPressed: _load, expand: false),
            ],
          ),
        ),
      );
    }
    final quiz = _quiz;
    if (quiz == null || quiz.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Test')),
        body: const Center(child: Text('Savol yo\'q')),
      );
    }
    final q = quiz.questions[_current];
    final selected = _answers[q.id];
    final progress = (_current + 1) / quiz.questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Savol ${_current + 1}/${quiz.questions.length}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.border,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(q.question,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 20),
                  ...List.generate(q.options.length, (i) {
                    final isSelected = selected == i;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => setState(() => _answers[q.id] = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.bg,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.border, width: 2),
                                ),
                                child: Text(
                                  String.fromCharCode(65 + i),
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.ink,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  q.options[i],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (_current > 0)
                      Expanded(
                        child: DuoButton(
                          label: 'Orqaga',
                          variant: DuoButtonVariant.outline,
                          onPressed: () => setState(() => _current -= 1),
                        ),
                      ),
                    if (_current > 0) const SizedBox(width: 10),
                    Expanded(
                      child: DuoButton(
                        label: _current == quiz.questions.length - 1
                            ? 'Tugatish'
                            : 'Keyingi',
                        onPressed: selected == null
                            ? null
                            : () {
                                if (_current == quiz.questions.length - 1) {
                                  _submit();
                                } else {
                                  setState(() => _current += 1);
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
