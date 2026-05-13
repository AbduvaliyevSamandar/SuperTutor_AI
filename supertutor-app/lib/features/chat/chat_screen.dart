import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../core/theme.dart';
import '../../widgets/avatar_view.dart';
import '../auth/auth_controller.dart';
import '../dashboard/stats_repository.dart';
import 'chat_controller.dart';
import 'chat_models.dart';
import 'chat_repository.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String subject;
  const ChatScreen({super.key, required this.subject});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _player = AudioPlayer();
  final _recorder = AudioRecorder();
  bool _speaking = false;
  bool _recording = false;
  bool _transcribing = false;

  String? _sessionId;
  DateTime? _sessionStart;
  int _messagesCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSession());
  }

  Future<void> _startSession() async {
    if (!ref.read(authControllerProvider).isAuthenticated) return;
    try {
      _sessionId = await ref
          .read(statsRepositoryProvider)
          .startSession(widget.subject);
      _sessionStart = DateTime.now();
    } catch (_) {
      _sessionId = null;
    }
  }

  Future<void> _updateSession() async {
    if (_sessionId == null || _sessionStart == null) return;
    final duration = DateTime.now().difference(_sessionStart!).inSeconds;
    try {
      await ref.read(statsRepositoryProvider).updateSession(
            _sessionId!,
            durationSeconds: duration,
            messagesCount: _messagesCount,
          );
    } catch (_) {}
  }

  Future<void> _endSession() async {
    if (_sessionId == null) return;
    try {
      await _updateSession();
      await ref.read(statsRepositoryProvider).endSession(_sessionId!);
    } catch (_) {}
  }

  String get _subjectTitle => switch (widget.subject) {
        'math' => 'Matematika',
        'english' => 'Ingliz tili',
        _ => widget.subject,
      };

  String get _subjectEmoji => switch (widget.subject) {
        'math' => '📐',
        'english' => '🇬🇧',
        _ => '🎓',
      };

  Color get _subjectColor => switch (widget.subject) {
        'math' => AppColors.fire,
        'english' => AppColors.secondary,
        _ => AppColors.primary,
      };

  String get _voiceLang => widget.subject == 'math' ? 'uz' : 'en';

  @override
  void dispose() {
    _endSession();
    _input.dispose();
    _scroll.dispose();
    _player.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _onSend() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    final ctrl = ref.read(chatControllerProvider(widget.subject).notifier);
    await ctrl.send(text);
    _messagesCount += 1;
    final last =
        ref.read(chatControllerProvider(widget.subject)).messages.lastOrNull;
    if (last != null && last.role == 'assistant') {
      _speak(last.content);
    }
    _updateSession();
    _scrollToBottom();
  }

  Future<void> _speak(String text) async {
    try {
      setState(() => _speaking = true);
      final repo = ref.read(chatRepositoryProvider);
      final audio = await repo.synthesize(text, language: _voiceLang);
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

  Future<void> _toggleRecord() async {
    if (kIsWeb) {
      _showMessage('Ovozli yozish hozircha faqat mobile ilovada.');
      return;
    }
    if (_recording) {
      final path = await _recorder.stop();
      setState(() => _recording = false);
      if (path != null) await _sendAudio(path);
      return;
    }
    if (!await _recorder.hasPermission()) {
      _showMessage('Mikrofon ruxsati berilmadi.');
      return;
    }
    final dir = await getTemporaryDirectory();
    final filePath =
        '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 16000),
      path: filePath,
    );
    setState(() => _recording = true);
  }

  Future<void> _sendAudio(String path) async {
    setState(() => _transcribing = true);
    try {
      final bytes = await File(path).readAsBytes();
      final repo = ref.read(chatRepositoryProvider);
      final text = await repo.transcribe(
        bytes.toList(),
        language: _voiceLang == 'uz' ? null : _voiceLang,
        filename: 'audio.m4a',
      );
      if (text.trim().isEmpty) {
        _showMessage('Ovoz tushunarli emas, qaytadan urinib ko\'ring.');
        return;
      }
      _input.text = text;
      await _onSend();
    } catch (e) {
      _showMessage('STT xatosi: $e');
    } finally {
      if (mounted) setState(() => _transcribing = false);
    }
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider(widget.subject));
    final busy = state.sending || _transcribing;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(_subjectEmoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(_subjectTitle),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _subjectColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.bolt_rounded, color: _subjectColor, size: 16),
                  const SizedBox(width: 4),
                  Text('$_messagesCount XP',
                      style: TextStyle(
                          color: _subjectColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          AvatarView(speaking: _speaking),
          if (state.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              color: AppColors.heart.withValues(alpha: 0.1),
              child: Text(state.error!,
                  style: const TextStyle(
                      color: AppColors.heartDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
          Expanded(
            child: state.messages.isEmpty
                ? _EmptyChat(subject: widget.subject, accent: _subjectColor)
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: state.messages.length + (state.sending ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= state.messages.length) {
                        return _TypingBubble(accent: _subjectColor);
                      }
                      return _Bubble(
                          message: state.messages[i], accent: _subjectColor);
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.bg,
                border: Border(
                    top: BorderSide(color: AppColors.border, width: 1.5)),
              ),
              child: Row(
                children: [
                  _MicButton(
                    recording: _recording,
                    onTap: busy && !_recording ? null : _toggleRecord,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      onSubmitted: (_) => _onSend(),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: _recording
                            ? 'Yozilmoqda...'
                            : 'Xabar yozing...',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SendButton(
                    enabled: !busy,
                    onTap: busy ? null : _onSend,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final Color accent;
  const _Bubble({required this.message, required this.accent});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('🦉', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72),
              decoration: BoxDecoration(
                color: isUser ? accent : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? null
                    : Border.all(color: AppColors.border, width: 1.5),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isUser ? Colors.white : AppColors.ink,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  final Color accent;
  const _TypingBubble({required this.accent});

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 1))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text('🦉', style: TextStyle(fontSize: 18)),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
              bottomLeft: Radius.circular(4),
            ),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) {
              int dots = ((_c.value * 4).floor() % 4);
              return Text(
                '·' * (dots == 0 ? 1 : dots),
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 0.5,
                    color: AppColors.inkLight),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmptyChat extends StatelessWidget {
  final String subject;
  final Color accent;
  const _EmptyChat({required this.subject, required this.accent});

  @override
  Widget build(BuildContext context) {
    final hint = subject == 'math'
        ? 'Masala yozing yoki mikrofon orqali aytib bering'
        : 'Hi! / How are you? deb yozing yoki gapiring';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Text('💬', style: TextStyle(fontSize: 40)),
            ),
            const SizedBox(height: 16),
            Text('Suhbatni boshlang',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(hint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.inkLight, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  final bool recording;
  final VoidCallback? onTap;
  const _MicButton({required this.recording, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = recording ? AppColors.heart : AppColors.secondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: onTap == null ? AppColors.inkLighter : color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: (onTap == null
                      ? AppColors.inkLighter
                      : (recording
                          ? AppColors.heartDark
                          : AppColors.secondaryDark))
                  .withValues(alpha: 0.85),
              offset: const Offset(0, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Icon(
          recording ? Icons.stop_rounded : Icons.mic_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback? onTap;
  const _SendButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : AppColors.inkLighter,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: enabled
                  ? AppColors.primaryDark
                  : AppColors.inkLighter.withValues(alpha: 0.8),
              offset: const Offset(0, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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
