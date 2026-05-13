import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../widgets/duo_button.dart';
import '../../widgets/sound_effects.dart';
import '../chat/chat_repository.dart';
import '../currency/currency_controller.dart';
import '../auth/auth_controller.dart';

class ListeningExerciseScreen extends ConsumerStatefulWidget {
  final String subject;
  const ListeningExerciseScreen({super.key, this.subject = 'english'});

  @override
  ConsumerState<ListeningExerciseScreen> createState() =>
      _ListeningExerciseScreenState();
}

class _ListeningExerciseScreenState
    extends ConsumerState<ListeningExerciseScreen> {
  final _input = TextEditingController();
  final _player = AudioPlayer();
  String? _target;
  String? _translation;
  String _lang = 'en';
  bool _loading = true;
  bool? _isCorrect;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _isCorrect = null;
      _target = null;
      _input.clear();
    });
    try {
      final dio = ref.read(dioProvider);
      final r = await dio.get('/listening/sentence',
          queryParameters: {'subject': widget.subject, 'level': 'A2'});
      _target = r.data['text'] as String;
      _translation = r.data['translation_uz'] as String?;
      _lang = (r.data['language_code'] as String?) ?? 'en';
      setState(() => _loading = false);
      _play();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _play() async {
    if (_target == null) return;
    try {
      final repo = ref.read(chatRepositoryProvider);
      final audio = await repo.synthesize(_target!, language: _lang);
      await _player.setAudioSource(_MemoryAudioSource(audio));
      await _player.play();
    } catch (_) {}
  }

  String _normalize(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'''[\.,!?;:'"]'''), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  Future<void> _check() async {
    if (_target == null) return;
    final guess = _normalize(_input.text);
    final answer = _normalize(_target!);
    final correct = guess == answer;
    setState(() => _isCorrect = correct);
    if (correct) {
      SoundEffects.correct();
      if (ref.read(authControllerProvider).isAuthenticated) {
        await ref.read(currencyControllerProvider.notifier).awardXp(8, reason: 'listening');
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
      appBar: AppBar(
        title: const Text('Tinglash mashqi'),
        actions: [
          IconButton(
              tooltip: 'Yangi gap',
              icon: const Icon(Icons.refresh),
              onPressed: _load),
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
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      const Text('🎧',
                          style: TextStyle(fontSize: 64)),
                      const SizedBox(height: 8),
                      Text(
                        'Tugmani bosib gapni tinglang va yozing',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 20),
                      DuoButton(
                        label: '🔊  Yana eshitish',
                        variant: DuoButtonVariant.secondary,
                        onPressed: _play,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _input,
                        autofocus: true,
                        maxLines: 3,
                        enabled: _isCorrect != true,
                        decoration: const InputDecoration(
                          hintText: 'Eshitganingizni yozing...',
                        ),
                      ),
                      if (_isCorrect != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (_isCorrect! ? AppColors.primary : AppColors.heart)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isCorrect! ? '✓ To\'g\'ri! +8 XP' : 'Xato',
                                style: TextStyle(
                                    color: _isCorrect!
                                        ? AppColors.primary
                                        : AppColors.heartDark,
                                    fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 6),
                              Text('To\'g\'ri javob:',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.inkLight,
                                      fontSize: 12)),
                              Text(_target ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              if (_translation != null && _translation!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(_translation!,
                                      style: const TextStyle(
                                          color: AppColors.inkLight,
                                          fontStyle: FontStyle.italic)),
                                ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          if (_isCorrect == null)
                            Expanded(
                              child: DuoButton(
                                label: 'Tekshirish',
                                onPressed:
                                    _input.text.isEmpty ? null : _check,
                              ),
                            ),
                          if (_isCorrect != null)
                            Expanded(
                              child: DuoButton(
                                label: 'Keyingisi',
                                onPressed: _load,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _MemoryAudioSource extends StreamAudioSource {
  final List<int> bytes;
  _MemoryAudioSource(this.bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= bytes.length;
    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(bytes.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}
