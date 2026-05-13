import 'dart:async';
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
import '../chat/chat_repository.dart';

class IeltsSpeakingScreen extends ConsumerStatefulWidget {
  const IeltsSpeakingScreen({super.key});

  @override
  ConsumerState<IeltsSpeakingScreen> createState() =>
      _IeltsSpeakingScreenState();
}

class _IeltsSpeakingScreenState extends ConsumerState<IeltsSpeakingScreen> {
  final _recorder = AudioRecorder();
  List<dynamic> _questions = const [];
  int _index = 0;
  bool _recording = false;
  bool _loading = true;
  bool _busy = false;
  Timer? _ticker;
  int _remainingSeconds = 0;
  final List<Map<String, String>> _answers = [];
  Map<String, dynamic>? _feedback;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      final r = await ref.read(dioProvider).post('/ielts/speaking/start');
      setState(() {
        _questions = (r.data['questions'] as List?) ?? const [];
        _loading = false;
        _index = 0;
        _answers.clear();
        _feedback = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _startTimer(int seconds) {
    _ticker?.cancel();
    setState(() => _remainingSeconds = seconds);
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (_remainingSeconds <= 0) {
        t.cancel();
        _stopRecording();
        return;
      }
      setState(() => _remainingSeconds -= 1);
    });
  }

  Future<List<int>> _readRecording(String pathOrUrl) async {
    if (kIsWeb || pathOrUrl.startsWith('blob:') || pathOrUrl.startsWith('http')) {
      final dio = Dio();
      final r = await dio.get<List<int>>(pathOrUrl,
          options: Options(responseType: ResponseType.bytes));
      return r.data ?? const [];
    }
    return File(pathOrUrl).readAsBytes();
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) {
      setState(() => _error = 'Mikrofon ruxsati yo\'q');
      return;
    }
    String? filePath;
    if (!kIsWeb) {
      final dir = await getTemporaryDirectory();
      filePath = '${dir.path}/ielts_$_index.m4a';
    }
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 16000),
      path: filePath ?? '',
    );
    setState(() => _recording = true);
    final q = Map<String, dynamic>.from(_questions[_index]);
    _startTimer(q['seconds'] ?? 60);
  }

  Future<void> _stopRecording() async {
    if (!_recording) return;
    _ticker?.cancel();
    final path = await _recorder.stop();
    setState(() {
      _recording = false;
      _busy = true;
    });
    String transcript = '';
    if (path != null) {
      try {
        final bytes = await _readRecording(path);
        final repo = ref.read(chatRepositoryProvider);
        transcript = await repo.transcribe(bytes,
            language: 'en',
            filename: kIsWeb ? 'audio.webm' : 'audio.m4a');
      } catch (_) {}
    }
    final q = Map<String, dynamic>.from(_questions[_index]);
    _answers.add({
      'question': (q['text'] ?? '').toString(),
      'transcript': transcript,
    });
    setState(() {
      _busy = false;
      if (_index + 1 < _questions.length) {
        _index += 1;
      } else {
        _finish();
      }
    });
  }

  Future<void> _finish() async {
    setState(() => _busy = true);
    try {
      final r = await ref.read(dioProvider).post('/ielts/speaking/feedback', data: {
        'answers': _answers,
      });
      setState(() {
        _feedback = Map<String, dynamic>.from(r.data);
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _busy = false;
      });
    }
  }

  String _fmt(int s) {
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('IELTS Speaking')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text(_error!, textAlign: TextAlign.center)),
                )
              : _feedback != null
                  ? _Feedback(data: _feedback!)
                  : _busy
                      ? const Center(child: CircularProgressIndicator())
                      : _buildQuestion(),
    );
  }

  Widget _buildQuestion() {
    final q = Map<String, dynamic>.from(_questions[_index]);
    final part = q['part'] ?? 1;
    final text = q['text'] ?? '';
    final seconds = q['seconds'] ?? 60;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: (_index + 1) / _questions.length,
            minHeight: 6,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text('Part $part · Savol ${_index + 1}/${_questions.length}',
              style: const TextStyle(
                  color: AppColors.inkLight, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: Text(text,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.4)),
          ),
          const SizedBox(height: 16),
          if (_recording)
            Column(
              children: [
                Text(_fmt(_remainingSeconds),
                    style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppColors.heart)),
                const Text('Yozilmoqda... aniq gapiring',
                    style: TextStyle(
                        color: AppColors.inkLight,
                        fontWeight: FontWeight.w600)),
              ],
            )
          else
            Text('Vaqt: ${_fmt(seconds)}',
                style: const TextStyle(
                    color: AppColors.inkLight, fontWeight: FontWeight.w700)),
          const Spacer(),
          DuoButton(
            label: _recording ? 'To\'xtatish va keyingi' : '🎤  Javob berishni boshlash',
            variant:
                _recording ? DuoButtonVariant.danger : DuoButtonVariant.secondary,
            onPressed: _recording ? _stopRecording : _startRecording,
          ),
        ],
      ),
    );
  }
}

class _Feedback extends StatelessWidget {
  final Map<String, dynamic> data;
  const _Feedback({required this.data});

  Color _band(double b) {
    if (b >= 7) return AppColors.primary;
    if (b >= 5.5) return AppColors.gold;
    return AppColors.heart;
  }

  Widget _row(String label, double v) {
    final color = _band(v);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style:
                      const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color, width: 2),
            ),
            child: Text(v.toStringAsFixed(1),
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 14)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final overall = (data['overall'] as num?)?.toDouble() ?? 0;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_band(overall).withValues(alpha: 0.9), _band(overall)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Text('🎓', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 4),
              Text(overall.toStringAsFixed(1),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 60,
                      height: 1)),
              const Text('Overall Band Score',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _row('Fluency & Coherence', (data['fluency'] as num?)?.toDouble() ?? 0),
        _row('Lexical Resource', (data['lexical'] as num?)?.toDouble() ?? 0),
        _row('Grammar', (data['grammar'] as num?)?.toDouble() ?? 0),
        _row('Pronunciation', (data['pronunciation'] as num?)?.toDouble() ?? 0),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            data['feedback'] ?? '',
            style: const TextStyle(
                fontWeight: FontWeight.w600, height: 1.45),
          ),
        ),
        const SizedBox(height: 20),
        DuoButton(label: 'Tugatish', onPressed: () => Navigator.pop(context)),
      ],
    );
  }
}
