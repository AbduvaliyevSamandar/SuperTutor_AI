import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../widgets/duo_button.dart';
import '../chat/chat_repository.dart';

final podcastProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final r = await ref.read(dioProvider).get('/podcast/today');
  return Map<String, dynamic>.from(r.data);
});

class PodcastScreen extends ConsumerStatefulWidget {
  const PodcastScreen({super.key});

  @override
  ConsumerState<PodcastScreen> createState() => _PodcastScreenState();
}

class _PodcastScreenState extends ConsumerState<PodcastScreen> {
  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _play(String script) async {
    try {
      setState(() => _playing = true);
      final repo = ref.read(chatRepositoryProvider);
      final audio = await repo.synthesize(script, language: 'en');
      await _player.setAudioSource(_MemorySource(audio));
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

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(podcastProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kunlik podcast'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(podcastProvider),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: Text('Yuklab bo\'lmadi: $e', textAlign: TextAlign.center)),
        ),
        data: (data) {
          final script = data['script'] ?? '';
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB45A), AppColors.fire],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🎙️ TODAY\'S PODCAST',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 0.8)),
                    const SizedBox(height: 4),
                    Text(data['title'] ?? '',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 20)),
                    const SizedBox(height: 12),
                    DuoButton(
                      label: _playing ? '⏸ Pauza' : '▶  Tinglash',
                      variant: DuoButtonVariant.gold,
                      onPressed: () => _playing
                          ? _player.pause().then((_) => setState(() => _playing = false))
                          : _play(script),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if ((data['summary_uz'] ?? '').toString().isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🇺🇿 Qisqacha:',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary)),
                      const SizedBox(height: 4),
                      Text(data['summary_uz'],
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              height: 1.45)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(script,
                  style: const TextStyle(
                      fontSize: 15, height: 1.6, fontWeight: FontWeight.w500)),
            ],
          );
        },
      ),
    );
  }
}

class _MemorySource extends StreamAudioSource {
  final List<int> bytes;
  _MemorySource(this.bytes);

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
