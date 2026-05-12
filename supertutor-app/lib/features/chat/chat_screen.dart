import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../widgets/avatar_view.dart';
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

  String get _subjectTitle => switch (widget.subject) {
        'math' => 'Matematika',
        'english' => 'Ingliz tili',
        _ => widget.subject,
      };

  String get _voiceLang => widget.subject == 'math' ? 'uz' : 'en';

  @override
  void dispose() {
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
    final last =
        ref.read(chatControllerProvider(widget.subject)).messages.lastOrNull;
    if (last != null && last.role == 'assistant') {
      _speak(last.content);
    }
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
      _showMessage('Ovozli yozish hozircha faqat mobile ilovada ishlaydi.');
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
      appBar: AppBar(title: Text(_subjectTitle)),
      body: Column(
        children: [
          AvatarView(speaking: _speaking),
          if (state.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.red.withValues(alpha: 0.1),
              child: Text(state.error!,
                  style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: state.messages.length,
              itemBuilder: (context, i) => _Bubble(message: state.messages[i]),
            ),
          ),
          if (busy) const LinearProgressIndicator(minHeight: 2),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  IconButton.filled(
                    onPressed: busy ? null : _toggleRecord,
                    icon: Icon(_recording ? Icons.stop : Icons.mic),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          _recording ? Colors.red : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      onSubmitted: (_) => _onSend(),
                      decoration: InputDecoration(
                        hintText:
                            _recording ? 'Yozilmoqda...' : 'Yozing yoki mikrofondan gapiring...',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    onPressed: busy ? null : _onSend,
                    icon: const Icon(Icons.send),
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
  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(message.content),
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
