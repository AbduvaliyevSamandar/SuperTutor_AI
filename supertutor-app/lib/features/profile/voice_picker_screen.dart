import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/api_client.dart';
import '../../core/error_messages.dart';
import '../../core/theme.dart';
import '../../widgets/haptics.dart';
import '../chat/chat_repository.dart';
import 'settings_storage.dart';

class _Voice {
  final String id;
  final String label;
  final String gender;
  final String language;
  _Voice({
    required this.id,
    required this.label,
    required this.gender,
    required this.language,
  });
  factory _Voice.fromJson(Map<String, dynamic> j) => _Voice(
        id: j['id'] as String,
        label: j['label'] as String,
        gender: (j['gender'] ?? 'F') as String,
        language: (j['language'] ?? 'en') as String,
      );
}

final _voiceListProvider =
    FutureProvider.autoDispose<Map<String, List<_Voice>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final r = await dio.get('/tts/voices');
  final items = (r.data['items'] as List<dynamic>?) ?? [];
  final voices = items
      .map((e) => _Voice.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
  final grouped = <String, List<_Voice>>{};
  for (final v in voices) {
    grouped.putIfAbsent(v.language, () => []).add(v);
  }
  return grouped;
});

class VoicePickerScreen extends ConsumerStatefulWidget {
  const VoicePickerScreen({super.key});

  @override
  ConsumerState<VoicePickerScreen> createState() => _VoicePickerScreenState();
}

class _VoicePickerScreenState extends ConsumerState<VoicePickerScreen> {
  final _player = AudioPlayer();
  String? _previewing;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  static const _langTitles = {
    'en': '🇬🇧 Ingliz tili',
    'uz': '🇺🇿 O‘zbek tili',
    'ru': '🇷🇺 Rus tili',
    'de': '🇩🇪 Nemis tili',
    'tr': '🇹🇷 Turk tili',
  };

  static const _previewText = {
    'en': 'Hello! I am your AI tutor. Let\'s learn together.',
    'uz': 'Salom! Men sizning AI o\'qituvchingizman.',
    'ru': 'Привет! Я ваш AI-преподаватель.',
    'de': 'Hallo! Ich bin dein KI-Tutor.',
    'tr': 'Merhaba! Ben senin yapay zekâ öğretmeninim.',
  };

  Future<void> _preview(_Voice v) async {
    try {
      setState(() => _previewing = v.id);
      Haptics.tap();
      final repo = ref.read(chatRepositoryProvider);
      final text = _previewText[v.language] ?? 'Hello.';
      final audio =
          await repo.synthesize(text, language: v.language, voice: v.id);
      await _player.setAudioSource(_MemAudio(audio));
      await _player.play();
      _player.playerStateStream
          .firstWhere((s) => s.processingState == ProcessingState.completed)
          .then((_) {
        if (mounted) setState(() => _previewing = null);
      });
    } catch (e) {
      if (mounted) {
        setState(() => _previewing = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e))),
        );
      }
    }
  }

  Future<void> _select(_Voice v) async {
    await ref
        .read(settingsControllerProvider.notifier)
        .setVoiceFor(v.language, v.id);
    Haptics.success();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_voiceListProvider);
    final settings = ref.watch(settingsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('AI ovozi')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              friendlyError(e),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.inkLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        data: (grouped) {
          final order = ['en', 'uz', 'ru', 'de', 'tr'];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final lang in order)
                if (grouped[lang]?.isNotEmpty == true) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Text(
                      _langTitles[lang] ?? lang.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.inkLight,
                      ),
                    ),
                  ),
                  ...grouped[lang]!.map((v) {
                    final selected = settings.voiceFor(lang) == v.id;
                    final isPreviewing = _previewing == v.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.border,
                            width: selected ? 2 : 1.5,
                          ),
                        ),
                        child: ListTile(
                          onTap: () => _select(v),
                          leading: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: (v.gender == 'M'
                                      ? AppColors.secondary
                                      : AppColors.heart)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              v.gender == 'M' ? '👨' : '👩',
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          title: Text(
                            v.label,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          subtitle: selected
                              ? const Text('Tanlangan',
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12))
                              : null,
                          trailing: IconButton(
                            icon: Icon(
                              isPreviewing
                                  ? Icons.volume_up_rounded
                                  : Icons.play_circle_outline,
                              color: isPreviewing
                                  ? AppColors.primary
                                  : AppColors.inkLight,
                            ),
                            onPressed:
                                isPreviewing ? null : () => _preview(v),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _MemAudio extends StreamAudioSource {
  final List<int> bytes;
  _MemAudio(this.bytes);

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
