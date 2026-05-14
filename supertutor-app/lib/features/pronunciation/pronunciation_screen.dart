import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../widgets/duo_button.dart';
import '../../widgets/haptics.dart';
import '../../widgets/sound_effects.dart';
import '../auth/auth_controller.dart';
import '../currency/currency_controller.dart';

const _sentences = [
  // A1-A2 (short, common)
  'I would like a cup of coffee, please.',
  'Where is the nearest bus station?',
  'The weather is beautiful today.',
  'Can you help me find my passport?',
  'I usually wake up at seven in the morning.',
  'Could you repeat that more slowly, please?',
  'My name is Sam and I am from Uzbekistan.',
  'How much does this book cost?',
  'I want to learn English as fast as possible.',
  'What time does the museum open tomorrow?',
  // B1 (medium)
  'Learning a new language takes time and practice.',
  'She has been studying English for two years.',
  'If it rains tomorrow, I will stay at home.',
  'The train was delayed because of heavy snow.',
  'I am looking forward to meeting your family.',
  'Could you tell me the best way to the airport?',
  'I think reading books is more useful than watching TV.',
  'My favorite season is autumn because it is colorful.',
  'We have to finish this project before next Friday.',
  'I have lived in this city for almost five years.',
  // B2 (longer, complex)
  'Despite the difficulties, she managed to complete the marathon.',
  'The new policy is expected to significantly reduce traffic congestion.',
  'Although he was tired, he kept working until the project was done.',
  'Scientists are constantly searching for cleaner sources of energy.',
  'If I had known about the meeting, I would have arrived earlier.',
  'The committee decided to postpone the decision until further notice.',
  'Despite numerous setbacks, the research team eventually succeeded.',
  'Many young people prefer flexible jobs that allow remote working.',
  'The author argues that technology has fundamentally changed education.',
  'A balanced diet combined with regular exercise improves overall health.',
];

class PronunciationScreen extends ConsumerStatefulWidget {
  const PronunciationScreen({super.key});

  @override
  ConsumerState<PronunciationScreen> createState() =>
      _PronunciationScreenState();
}

class _PronunciationScreenState extends ConsumerState<PronunciationScreen> {
  final _recorder = AudioRecorder();
  int _index = 0;
  bool _recording = false;
  bool _checking = false;
  Map<String, dynamic>? _result;
  String? _error;

  String get _target => _sentences[_index % _sentences.length];

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _toggleRecord() async {
    Haptics.tap();
    if (_recording) {
      final path = await _recorder.stop();
      setState(() => _recording = false);
      if (path != null) await _score(path);
      return;
    }
    if (!await _recorder.hasPermission()) {
      setState(() => _error = 'Mikrofon ruxsati yo\'q');
      return;
    }
    String? filePath;
    if (!kIsWeb) {
      final dir = await getTemporaryDirectory();
      filePath = '${dir.path}/pron_${DateTime.now().millisecondsSinceEpoch}.m4a';
    }
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 16000),
      path: filePath ?? '',
    );
    setState(() {
      _recording = true;
      _result = null;
      _error = null;
    });
  }

  Future<List<int>> _readRecording(String pathOrUrl) async {
    if (kIsWeb ||
        pathOrUrl.startsWith('blob:') ||
        pathOrUrl.startsWith('http')) {
      final dio = Dio();
      final r = await dio.get<List<int>>(pathOrUrl,
          options: Options(responseType: ResponseType.bytes));
      return r.data ?? const [];
    }
    return File(pathOrUrl).readAsBytes();
  }

  Future<void> _score(String path) async {
    setState(() => _checking = true);
    try {
      final bytes = await _readRecording(path);
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes,
            filename: kIsWeb ? 'audio.webm' : 'audio.m4a'),
        'target': _target,
        'language': 'en',
      });
      final r = await ref.read(dioProvider).post('/pronunciation/score', data: form);
      final data = Map<String, dynamic>.from(r.data);
      setState(() => _result = data);
      final score = data['score'] as int;
      if (score >= 80) {
        SoundEffects.correct();
        Haptics.success();
        if (ref.read(authControllerProvider).isAuthenticated) {
          await ref
              .read(currencyControllerProvider.notifier)
              .awardXp(6, reason: 'pronunciation');
        }
      } else if (score >= 50) {
        SoundEffects.correct();
        Haptics.success();
      } else {
        SoundEffects.wrong();
        Haptics.error();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _next() {
    Haptics.tap();
    setState(() {
      _index += 1;
      _result = null;
      _error = null;
    });
  }

  String _levelLabel(int i) {
    if (i < 10) return 'A1-A2';
    if (i < 20) return 'B1';
    return 'B2';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Talaffuz mashqi'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_levelLabel(_index % _sentences.length),
                    style: const TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('🎙️', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 8),
            Text(
              '${(_index % _sentences.length) + 1} / ${_sentences.length}',
              style: const TextStyle(
                  color: AppColors.inkLight, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: Text(_target,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.4)),
            ),
            const SizedBox(height: 20),
            if (_result != null) _ResultView(result: _result!),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_error!,
                    style: const TextStyle(color: AppColors.heart)),
              ),
            const Spacer(),
            if (_checking)
              const CircularProgressIndicator()
            else if (_result == null)
              DuoButton(
                label: _recording ? 'To\'xtatish' : '🎤  Yozish',
                variant: _recording
                    ? DuoButtonVariant.danger
                    : DuoButtonVariant.secondary,
                onPressed: _toggleRecord,
              )
            else
              Row(
                children: [
                  Expanded(
                    child: DuoButton(
                      label: 'Qaytadan',
                      variant: DuoButtonVariant.outline,
                      onPressed: () => setState(() {
                        _result = null;
                        _error = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DuoButton(label: 'Keyingisi', onPressed: _next),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final Map<String, dynamic> result;
  const _ResultView({required this.result});

  @override
  Widget build(BuildContext context) {
    final score = result['score'] as int;
    final color = score >= 80
        ? AppColors.primary
        : score >= 50
            ? AppColors.gold
            : AppColors.heart;
    final words = (result['per_word'] as List?) ?? const [];
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color, width: 2),
          ),
          child: Text('$score%',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 22)),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: words.map((w) {
            final m = Map<String, dynamic>.from(w);
            final ok = m['correct'] == true;
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (ok ? AppColors.primary : AppColors.heart)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                m['word'] ?? '',
                style: TextStyle(
                  color: ok ? AppColors.primary : AppColors.heartDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(result['feedback'] ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.inkLight, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
