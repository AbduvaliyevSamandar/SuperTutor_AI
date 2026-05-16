import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../widgets/duo_button.dart';
import '../chat/chat_repository.dart';
import 'commute_repository.dart';

class CommuteScreen extends ConsumerStatefulWidget {
  const CommuteScreen({super.key});

  @override
  ConsumerState<CommuteScreen> createState() => _CommuteScreenState();
}

enum _Phase { idle, loading, playingPrompt, listening, evaluating, feedback, done }

class _CommuteScreenState extends ConsumerState<CommuteScreen> {
  final _player = AudioPlayer();
  final _recorder = AudioRecorder();
  CommuteLesson? _lesson;
  int _step = 0;
  bool _correct = false;
  _Phase _phase = _Phase.idle;
  Timer? _silenceTimer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _player.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _phase = _Phase.loading);
    try {
      final l = await ref
          .read(commuteRepositoryProvider)
          .lesson(language: 'english', level: 'A2');
      setState(() {
        _lesson = l;
        _step = 0;
        _phase = _Phase.idle;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yuklab bo\'lmadi: $e')),
        );
        setState(() => _phase = _Phase.idle);
      }
    }
  }

  CommuteStep? get _current =>
      (_lesson != null && _step < _lesson!.steps.length)
          ? _lesson!.steps[_step]
          : null;

  Future<void> _runStep() async {
    final step = _current;
    if (step == null) {
      setState(() => _phase = _Phase.done);
      return;
    }
    // 1. Speak the Uzbek prompt
    setState(() => _phase = _Phase.playingPrompt);
    try {
      final bytes = await ref
          .read(chatRepositoryProvider)
          .synthesize(step.prompt_uz, language: 'uz');
      final tmp = await getTemporaryDirectory();
      final f = File('${tmp.path}/commute_prompt.mp3');
      await f.writeAsBytes(bytes);
      await _player.setFilePath(f.path);
      await _player.play();
      await _player.playerStateStream.firstWhere(
        (s) => s.processingState == ProcessingState.completed,
      );
    } catch (_) {
      // Skip audio errors; show text and continue
    }

    if (!mounted) return;
    // 2. Listen for ~6 seconds
    setState(() => _phase = _Phase.listening);
    try {
      if (await _recorder.hasPermission()) {
        final tmp = await getTemporaryDirectory();
        final path = '${tmp.path}/commute_user_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder.start(const RecordConfig(), path: path);
        await Future.delayed(const Duration(seconds: 6));
        final saved = await _recorder.stop();
        if (saved != null) {
          final f = File(saved);
          final bytes = await f.readAsBytes();
          setState(() => _phase = _Phase.evaluating);
          final text = await ref
              .read(chatRepositoryProvider)
              .transcribe(bytes, language: 'en');
          _correct = _matches(text, step.target_en);
        }
      }
    } catch (_) {}

    if (!mounted) return;
    // 3. Speak feedback
    setState(() => _phase = _Phase.feedback);
    final fb = _correct
        ? 'A\'lo! ${step.target_en}'
        : 'Aslida: ${step.target_en}';
    try {
      final bytes = await ref
          .read(chatRepositoryProvider)
          .synthesize(fb, language: 'en');
      final tmp = await getTemporaryDirectory();
      final f = File('${tmp.path}/commute_fb.mp3');
      await f.writeAsBytes(bytes);
      await _player.setFilePath(f.path);
      await _player.play();
      await _player.playerStateStream.firstWhere(
        (s) => s.processingState == ProcessingState.completed,
      );
    } catch (_) {}

    if (!mounted) return;
    // 4. Next step
    setState(() => _step++);
    if (_step >= (_lesson?.steps.length ?? 0)) {
      setState(() => _phase = _Phase.done);
    } else {
      _runStep();
    }
  }

  bool _matches(String said, String target) {
    final a = _norm(said);
    final b = _norm(target);
    if (a.isEmpty) return false;
    // 60% word overlap is acceptable
    final aw = a.split(' ').toSet();
    final bw = b.split(' ').toSet();
    final inter = aw.intersection(bw).length;
    return inter / bw.length >= 0.6;
  }

  String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  @override
  Widget build(BuildContext context) {
    final step = _current;
    return Scaffold(
      backgroundColor: const Color(0xFF0F1024),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Yo\'lda mashq'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_lesson != null)
                LinearProgressIndicator(
                  value: _lesson!.steps.isEmpty
                      ? 0
                      : _step / _lesson!.steps.length,
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF6B5BE5)),
                  minHeight: 6,
                ),
              const SizedBox(height: 32),
              Text(
                _lesson?.title ?? '...',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 6),
              if (_lesson != null)
                Text(
                  '${_step + 1} / ${_lesson!.steps.length}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const SizedBox(height: 36),
              _OrbIndicator(phase: _phase),
              const SizedBox(height: 24),
              if (_phase == _Phase.idle && _lesson != null)
                DuoButton(
                  label: '▶  Boshlash',
                  variant: DuoButtonVariant.primary,
                  onPressed: _runStep,
                ),
              if (_phase == _Phase.loading)
                const CircularProgressIndicator(color: Colors.white),
              if (_phase == _Phase.playingPrompt && step != null)
                Text(
                  step.prompt_uz,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    height: 1.4,
                  ),
                ),
              if (_phase == _Phase.listening)
                const Text(
                  '🎙 Tinglayapman... ingliz tilida ayting',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              if (_phase == _Phase.evaluating)
                const Text(
                  'Tekshirilmoqda...',
                  style: TextStyle(color: Colors.white70),
                ),
              if (_phase == _Phase.feedback && step != null)
                Column(
                  children: [
                    Text(
                      _correct ? '✅ Yaxshi!' : '❌ Quyidagicha bo\'lardi:',
                      style: TextStyle(
                        color: _correct ? Colors.greenAccent : Colors.orangeAccent,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      step.target_en,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
              if (_phase == _Phase.done)
                Column(
                  children: [
                    const Text(
                      '🎉 Tugadi!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DuoButton(
                      label: 'Yangi mashq',
                      variant: DuoButtonVariant.primary,
                      onPressed: _load,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrbIndicator extends StatelessWidget {
  final _Phase phase;
  const _OrbIndicator({required this.phase});

  Color get _color {
    switch (phase) {
      case _Phase.listening:
        return Colors.redAccent;
      case _Phase.playingPrompt:
        return const Color(0xFF6B5BE5);
      case _Phase.feedback:
        return Colors.greenAccent;
      default:
        return Colors.white24;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [_color.withValues(alpha: 0.9), _color.withValues(alpha: 0.1)],
        ),
        boxShadow: [
          BoxShadow(
            color: _color.withValues(alpha: 0.5),
            blurRadius: 40,
            spreadRadius: 4,
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.headphones_rounded, color: Colors.white, size: 56),
      ),
    );
  }
}
