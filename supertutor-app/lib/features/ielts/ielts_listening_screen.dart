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

class IeltsListeningScreen extends ConsumerStatefulWidget {
  const IeltsListeningScreen({super.key});

  @override
  ConsumerState<IeltsListeningScreen> createState() =>
      _IeltsListeningScreenState();
}

class _IeltsListeningScreenState extends ConsumerState<IeltsListeningScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  final Map<int, int> _answers = {};
  Map<String, dynamic>? _result;
  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;

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
      _data = null;
      _result = null;
      _answers.clear();
    });
    try {
      final r = await ref.read(dioProvider).get('/ielts/listening/test');
      setState(() {
        _data = Map<String, dynamic>.from(r.data);
        _loading = false;
      });
      _play();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _play() async {
    if (_data == null) return;
    try {
      setState(() => _playing = true);
      final repo = ref.read(chatRepositoryProvider);
      final audio =
          await repo.synthesize(_data!['script'] ?? '', language: 'en');
      await _player.setAudioSource(_MemoryAudioSource(audio));
      await _player.play();
      _player.playerStateStream
          .firstWhere((s) => s.processingState == ProcessingState.completed)
          .then((_) {
        if (mounted) setState(() => _playing = false);
      });
    } catch (_) {
      if (mounted) setState(() => _playing = false);
    }
  }

  Future<void> _submit() async {
    if (_data == null) return;
    final qs = (_data!['questions'] as List);
    final ans = List<int>.generate(qs.length, (i) => _answers[i] ?? -1);
    try {
      final r = await ref.read(dioProvider).post('/ielts/listening/check',
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
            .awardXp(12, reason: 'ielts_listening');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('IELTS Listening')),
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
                  : _buildQuestions(),
    );
  }

  Widget _buildQuestions() {
    final qs = (_data!['questions'] as List);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.35),
                  width: 2),
            ),
            child: Row(
              children: [
                const Text('🎧', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(_data!['title'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                ),
                IconButton(
                  icon: Icon(
                      _playing ? Icons.volume_up : Icons.replay,
                      color: AppColors.secondary),
                  onPressed: _play,
                  tooltip: 'Yana eshitish',
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
                                  ? AppColors.secondary.withValues(alpha: 0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: sel
                                    ? AppColors.secondary
                                    : AppColors.border,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(String.fromCharCode(65 + oi),
                                    style: TextStyle(
                                        color: sel
                                            ? AppColors.secondary
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
            child: DuoButton(
              label: 'Tugatish',
              onPressed: _answers.length == qs.length ? _submit : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final pct = _result!['percentage'] as int? ?? 0;
    final c = pct >= 70
        ? AppColors.primary
        : pct >= 50
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
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Text('🎧', style: TextStyle(fontSize: 48)),
              Text('$pct%',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.w800)),
              Text('${_result!['score']}/${_result!['total']} to\'g\'ri',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('+12 XP',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        DuoButton(label: 'Yangi test', onPressed: _load),
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
