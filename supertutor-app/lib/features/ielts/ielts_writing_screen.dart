import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../widgets/duo_button.dart';
import '../../widgets/sound_effects.dart';
import '../auth/auth_controller.dart';
import '../currency/currency_controller.dart';

class IeltsWritingScreen extends ConsumerStatefulWidget {
  const IeltsWritingScreen({super.key});

  @override
  ConsumerState<IeltsWritingScreen> createState() => _IeltsWritingScreenState();
}

class _IeltsWritingScreenState extends ConsumerState<IeltsWritingScreen> {
  String? _prompt;
  bool _loadingTask = true;
  bool _submitting = false;
  String? _error;
  final _essay = TextEditingController();
  Timer? _ticker;
  int _remaining = 40 * 60;
  Map<String, dynamic>? _feedback;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  @override
  void dispose() {
    _essay.dispose();
    _ticker?.cancel();
    super.dispose();
  }

  int get _wordCount {
    final text = _essay.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  void _startTimer() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (_remaining <= 0) {
        t.cancel();
        return;
      }
      setState(() => _remaining -= 1);
    });
  }

  Future<void> _loadTask() async {
    setState(() {
      _loadingTask = true;
      _error = null;
      _feedback = null;
      _essay.clear();
      _remaining = 40 * 60;
    });
    try {
      final r = await ref.read(dioProvider).get('/ielts/writing/task');
      setState(() {
        _prompt = r.data['prompt'] as String;
        _loadingTask = false;
      });
      _startTimer();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loadingTask = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_wordCount < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kamida 50 ta so\'z yozing')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final r = await ref.read(dioProvider).post('/ielts/writing/feedback',
          data: {'prompt': _prompt, 'essay': _essay.text});
      final data = Map<String, dynamic>.from(r.data);
      setState(() {
        _feedback = data;
        _submitting = false;
      });
      _ticker?.cancel();
      final overall = (data['overall'] as num?)?.toDouble() ?? 0;
      if (overall >= 6.0) {
        SoundEffects.correct();
      } else {
        SoundEffects.wrong();
      }
      if (ref.read(authControllerProvider).isAuthenticated) {
        await ref
            .read(currencyControllerProvider.notifier)
            .awardXp(20, reason: 'ielts_writing');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _submitting = false;
      });
    }
  }

  String _fmtTime(int s) {
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  Color _band(double b) {
    if (b >= 7) return AppColors.primary;
    if (b >= 5.5) return AppColors.gold;
    return AppColors.heart;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IELTS Writing Task 2'),
        actions: [
          if (_feedback == null)
            IconButton(
              tooltip: 'Yangi savol',
              icon: const Icon(Icons.refresh),
              onPressed: _loadTask,
            ),
        ],
      ),
      body: _loadingTask
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text(_error!, textAlign: TextAlign.center)),
                )
              : _feedback != null
                  ? _buildFeedback()
                  : _buildEssayForm(),
    );
  }

  Widget _buildEssayForm() {
    final wordCount = _wordCount;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TASK 2',
                    style: TextStyle(
                        color: AppColors.goldDark,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1)),
                const SizedBox(height: 6),
                Text(_prompt ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, height: 1.5)),
                const SizedBox(height: 8),
                const Text('Kamida 250 so\'z · 40 daqiqa',
                    style: TextStyle(
                        color: AppColors.inkLight,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(_fmtTime(_remaining),
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.fire)),
              const Spacer(),
              Text('$wordCount so\'z',
                  style: TextStyle(
                      color: wordCount >= 250
                          ? AppColors.primary
                          : AppColors.inkLight,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _essay,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Bu yerda essay yozing...',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _submitting
              ? const CircularProgressIndicator()
              : DuoButton(
                  label: 'Tekshirishga yuborish',
                  onPressed: wordCount >= 50 ? _submit : null,
                ),
        ],
      ),
    );
  }

  Widget _buildFeedback() {
    final f = _feedback!;
    final overall = (f['overall'] as num?)?.toDouble() ?? 0;
    final c = _band(overall);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [c.withValues(alpha: 0.9), c],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Text('✍️', style: TextStyle(fontSize: 48)),
              Text(overall.toStringAsFixed(1),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 60,
                      fontWeight: FontWeight.w800,
                      height: 1)),
              const Text('Overall Band',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('${f['word_count']} so\'z · +20 XP',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _row('Task Response', (f['task_response'] as num?)?.toDouble() ?? 0),
        _row('Coherence & Cohesion', (f['coherence'] as num?)?.toDouble() ?? 0),
        _row('Lexical Resource', (f['lexical'] as num?)?.toDouble() ?? 0),
        _row('Grammar', (f['grammar'] as num?)?.toDouble() ?? 0),
        const SizedBox(height: 12),
        if ((f['feedback'] as String?)?.isNotEmpty ?? false)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(f['feedback'],
                style: const TextStyle(
                    fontWeight: FontWeight.w600, height: 1.45)),
          ),
        if (((f['improved_intro'] as String?) ?? '').isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Yaxshilangan kirish',
              style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(f['improved_intro'],
                style: const TextStyle(
                    fontStyle: FontStyle.italic, fontWeight: FontWeight.w600)),
          ),
        ],
        if (f['improvements'] is List &&
            (f['improvements'] as List).isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Yaxshilash bo\'yicha maslahatlar',
              style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          ...((f['improvements'] as List).map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    Expanded(child: Text(s.toString())),
                  ],
                ),
              ))),
        ],
        const SizedBox(height: 20),
        DuoButton(label: 'Yangi savol', onPressed: _loadTask),
        const SizedBox(height: 8),
        DuoButton(
          label: 'Tugatish',
          variant: DuoButtonVariant.outline,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _row(String label, double v) {
    final color = _band(v);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color, width: 2),
            ),
            child: Text(v.toStringAsFixed(1),
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
