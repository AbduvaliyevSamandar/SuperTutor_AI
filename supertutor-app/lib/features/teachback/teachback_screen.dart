import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../core/theme.dart';
import '../chat/chat_repository.dart';
import 'teachback_repository.dart';

class TeachbackScreen extends ConsumerStatefulWidget {
  final String topic;
  final String? reference;
  const TeachbackScreen({super.key, required this.topic, this.reference});

  @override
  ConsumerState<TeachbackScreen> createState() => _TeachbackScreenState();
}

class _TeachbackScreenState extends ConsumerState<TeachbackScreen> {
  final _recorder = AudioRecorder();
  bool _recording = false;
  String _transcript = '';
  TeachbackScore? _score;
  bool _busy = false;

  Future<void> _toggleRecord() async {
    if (_recording) {
      final p = await _recorder.stop();
      setState(() => _recording = false);
      if (p != null) await _transcribeAndScore(p);
    } else {
      if (!await _recorder.hasPermission()) return;
      final tmp = await getTemporaryDirectory();
      final path = '${tmp.path}/teachback_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(), path: path);
      setState(() {
        _recording = true;
        _transcript = '';
        _score = null;
      });
    }
  }

  Future<void> _transcribeAndScore(String path) async {
    setState(() => _busy = true);
    try {
      final bytes = await File(path).readAsBytes();
      final text = await ref.read(chatRepositoryProvider).transcribe(bytes);
      setState(() => _transcript = text);
      final score = await ref.read(teachbackRepositoryProvider).evaluate(
            topic: widget.topic,
            reference: widget.reference,
            explanation: text,
          );
      setState(() => _score = score);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xato: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('O\'rgangan narsangizni gapiring')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mavzu',
                      style: TextStyle(
                        color: AppColors.inkLight,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.topic,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Mavzuni o\'z so\'zlaringiz bilan tushuntirib bering — bu Feynman texnikasi. Yodlaganmisiz yoki haqiqatan tushunganmisiz — bilib olamiz.',
                      style: TextStyle(
                        color: AppColors.inkLight,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Center(
                child: GestureDetector(
                  onTap: _busy ? null : _toggleRecord,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _recording
                            ? [Colors.red, Colors.redAccent]
                            : [const Color(0xFF6B5BE5), const Color(0xFF4A3DC6)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_recording ? Colors.red : const Color(0xFF6B5BE5))
                              .withValues(alpha: 0.4),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      _recording ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  _recording
                      ? 'Yozib olinmoqda... tugatish uchun bosing'
                      : _busy
                          ? 'Tahlil qilinmoqda...'
                          : 'Boshlash uchun bosing',
                  style: const TextStyle(
                    color: AppColors.inkLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_transcript.isNotEmpty) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_transcript),
                ),
              ],
              if (_score != null) ...[
                const SizedBox(height: 20),
                _ScoreCard(score: _score!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final TeachbackScore score;
  const _ScoreCard({required this.score});

  Color _c(int v) {
    if (v >= 8) return AppColors.primary;
    if (v >= 6) return AppColors.gold;
    return AppColors.heart;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B5BE5), Color(0xFFEC4899)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Umumiy baho',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${score.overall}/10',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ScoreBar(label: 'Aniqlik', value: score.accuracy, color: _c(score.accuracy)),
          _ScoreBar(label: 'To\'liqlik', value: score.completeness, color: _c(score.completeness)),
          _ScoreBar(label: 'Aniq tushunarli', value: score.clarity, color: _c(score.clarity)),
          _ScoreBar(label: 'Ravonlik', value: score.fluency, color: _c(score.fluency)),
          const SizedBox(height: 12),
          if (score.strengths.isNotEmpty) ...[
            const Text(
              '✓ Kuchli tomonlar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            ...score.strengths.map((s) => Padding(
                  padding: const EdgeInsets.only(left: 14, top: 2),
                  child: Text(
                    '• $s',
                    style: const TextStyle(color: Colors.white),
                  ),
                )),
            const SizedBox(height: 10),
          ],
          if (score.gaps.isNotEmpty) ...[
            const Text(
              '! Bo\'shliqlar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            ...score.gaps.map((s) => Padding(
                  padding: const EdgeInsets.only(left: 14, top: 2),
                  child: Text(
                    '• $s',
                    style: const TextStyle(color: Colors.white),
                  ),
                )),
            const SizedBox(height: 10),
          ],
          if (score.nextStep.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Text('📌 ', style: TextStyle(fontSize: 18)),
                  Expanded(
                    child: Text(
                      score.nextStep,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _ScoreBar({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value / 10,
                minHeight: 8,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
