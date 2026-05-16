import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../widgets/duo_button.dart';
import '../../widgets/sound_effects.dart';
import '../auth/auth_controller.dart';
import '../chat/chat_repository.dart';
import '../currency/currency_controller.dart';
import '../../widgets/grammar_tip_card.dart';

class StoriesScreen extends ConsumerStatefulWidget {
  const StoriesScreen({super.key});

  @override
  ConsumerState<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends ConsumerState<StoriesScreen> {
  Map<String, dynamic>? _story;
  bool _loading = true;
  String? _error;
  final Map<int, int> _answers = {};
  bool _showResult = false;
  final AudioPlayer _player = AudioPlayer();
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _answers.clear();
      _showResult = false;
    });
    try {
      final r = await ref
          .read(dioProvider)
          .get('/stories/generate', queryParameters: {'subject': 'english', 'level': 'A2'});
      setState(() {
        _story = Map<String, dynamic>.from(r.data);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _readAloud(String text) async {
    try {
      setState(() => _speaking = true);
      final repo = ref.read(chatRepositoryProvider);
      final audio = await repo.synthesize(text, language: 'en');
      await _player.setAudioSource(_MemoryAudioSource(audio));
      await _player.play();
      _player.playerStateStream
          .firstWhere((s) => s.processingState == ProcessingState.completed)
          .then((_) {
        if (mounted) setState(() => _speaking = false);
      });
    } catch (_) {
      if (mounted) setState(() => _speaking = false);
    }
  }

  Future<void> _finish() async {
    final questions = (_story!['questions'] as List);
    int correct = 0;
    for (int i = 0; i < questions.length; i++) {
      final q = Map<String, dynamic>.from(questions[i]);
      if (_answers[i] == q['correct_index']) correct++;
    }
    final score = correct;
    final total = questions.length;
    final percent = total == 0 ? 0 : (correct / total * 100).round();
    setState(() => _showResult = true);
    if (percent >= 50) {
      SoundEffects.correct();
    } else {
      SoundEffects.wrong();
    }
    if (ref.read(authControllerProvider).isAuthenticated && score > 0) {
      try {
        await ref
            .read(currencyControllerProvider.notifier)
            .awardXp(score * 4, reason: 'story');
      } catch (_) {}
    }
  }

  int get _correctCount {
    final qs = (_story!['questions'] as List);
    int c = 0;
    for (int i = 0; i < qs.length; i++) {
      final q = Map<String, dynamic>.from(qs[i]);
      if (_answers[i] == q['correct_index']) c++;
    }
    return c;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hikoyalar'),
        actions: [
          if (_story != null)
            IconButton(
              tooltip: 'Yangi hikoya',
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
              : _showResult
                  ? _buildResult()
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    final paragraphs = List<String>.from(_story!['paragraphs'] ?? const []);
    final questions = (_story!['questions'] as List);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const GrammarTipCard(),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Text('📖', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _story!['title'] ?? 'Story',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: 'O\'qib berish',
                icon: Icon(
                  _speaking ? Icons.volume_up : Icons.volume_up_outlined,
                  color: AppColors.gold,
                ),
                onPressed: () => _readAloud(paragraphs.join(' ')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...paragraphs.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                p,
                style: const TextStyle(
                    fontSize: 16, height: 1.55, fontWeight: FontWeight.w500),
              ),
            )),
        const SizedBox(height: 12),
        Text('Tushunchani tekshiramiz',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...List.generate(questions.length, (i) {
          final q = Map<String, dynamic>.from(questions[i]);
          final opts = List<String>.from(q['options'] ?? const []);
          final selected = _answers[i];
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
                Text(q['question'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 8),
                ...List.generate(opts.length, (oi) {
                  final isSel = selected == oi;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _answers[i] = oi),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSel
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isSel ? AppColors.primary : AppColors.border,
                              width: 2),
                        ),
                        child: Row(
                          children: [
                            Text(String.fromCharCode(65 + oi),
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: isSel
                                        ? AppColors.primary
                                        : AppColors.inkLight)),
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
        }),
        const SizedBox(height: 8),
        DuoButton(
          label: 'Tugatish',
          onPressed: _answers.length == questions.length ? _finish : null,
        ),
      ],
    );
  }

  Widget _buildResult() {
    final qs = (_story!['questions'] as List);
    final correct = _correctCount;
    final total = qs.length;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('🎉', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 8),
        Text('$correct / $total to\'g\'ri',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Center(
          child: Text(
              '+${correct * 4} XP',
              style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 20),
        DuoButton(label: 'Yangi hikoya', onPressed: _load),
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
