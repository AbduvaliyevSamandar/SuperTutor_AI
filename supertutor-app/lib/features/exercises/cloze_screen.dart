import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../widgets/duo_button.dart';
import '../../widgets/sound_effects.dart';
import '../auth/auth_controller.dart';
import '../currency/currency_controller.dart';

class ClozeExerciseScreen extends ConsumerStatefulWidget {
  final String subject;
  const ClozeExerciseScreen({super.key, this.subject = 'english'});

  @override
  ConsumerState<ClozeExerciseScreen> createState() => _ClozeExerciseScreenState();
}

class _ClozeExerciseScreenState extends ConsumerState<ClozeExerciseScreen> {
  String? _sentence;
  List<String> _options = const [];
  int _correct = 0;
  String? _translation;
  int? _selected;
  bool _checked = false;
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
      _selected = null;
      _checked = false;
    });
    try {
      final dio = ref.read(dioProvider);
      final r = await dio.get('/cloze/generate',
          queryParameters: {'subject': widget.subject, 'level': 'A2'});
      setState(() {
        _sentence = r.data['sentence'] as String?;
        _options = List<String>.from(r.data['options'] ?? const []);
        _correct = r.data['correct_index'] ?? 0;
        _translation = r.data['translation_uz'] as String?;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _check() async {
    if (_selected == null) return;
    setState(() => _checked = true);
    final correct = _selected == _correct;
    if (correct) {
      SoundEffects.correct();
      if (ref.read(authControllerProvider).isAuthenticated) {
        await ref.read(currencyControllerProvider.notifier).awardXp(5, reason: 'cloze');
      }
    } else {
      SoundEffects.wrong();
      if (ref.read(authControllerProvider).isAuthenticated) {
        try {
          await ref.read(currencyControllerProvider.notifier).loseHeart();
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gap to\'ldirish')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_error!, textAlign: TextAlign.center),
                ))
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text('📝', style: TextStyle(fontSize: 56)),
                      const SizedBox(height: 8),
                      const Text('Bo\'sh joyga to\'g\'ri so\'zni qo\'ying',
                          style: TextStyle(
                              color: AppColors.inkLight,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.border, width: 2),
                        ),
                        child: Text(
                          _sentence ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...List.generate(_options.length, (i) {
                        final isCorrect = i == _correct;
                        final isSelected = i == _selected;
                        Color border = AppColors.border;
                        Color bg = AppColors.surface;
                        if (_checked) {
                          if (isCorrect) {
                            border = AppColors.primary;
                            bg = AppColors.primary.withValues(alpha: 0.12);
                          } else if (isSelected && !isCorrect) {
                            border = AppColors.heart;
                            bg = AppColors.heart.withValues(alpha: 0.1);
                          }
                        } else if (isSelected) {
                          border = AppColors.secondary;
                          bg = AppColors.secondary.withValues(alpha: 0.1);
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: _checked
                                ? null
                                : () => setState(() => _selected = i),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: border, width: 2),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: border,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      String.fromCharCode(65 + i),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(_options[i],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15)),
                                  ),
                                  if (_checked && isCorrect)
                                    const Icon(Icons.check_circle,
                                        color: AppColors.primary),
                                  if (_checked && isSelected && !isCorrect)
                                    const Icon(Icons.cancel,
                                        color: AppColors.heart),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      if (_checked && _translation != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _translation!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.inkLight,
                              fontStyle: FontStyle.italic),
                        ),
                      ],
                      const Spacer(),
                      if (!_checked)
                        DuoButton(
                          label: 'Tekshirish',
                          onPressed: _selected == null ? null : _check,
                        ),
                      if (_checked)
                        DuoButton(
                          label: 'Keyingisi',
                          onPressed: _load,
                        ),
                    ],
                  ),
                ),
    );
  }
}
