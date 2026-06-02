import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error_messages.dart';
import 'chat_models.dart';
import 'chat_repository.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool sending;
  final String? error;
  final String streamingText;

  const ChatState({
    this.messages = const [],
    this.sending = false,
    this.error,
    this.streamingText = '',
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? sending,
    String? error,
    String? streamingText,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        sending: sending ?? this.sending,
        error: error,
        streamingText: streamingText ?? this.streamingText,
      );
}

class ChatController extends StateNotifier<ChatState> {
  final ChatRepository _repo;
  final String subject;

  String? scenarioRole;
  String? scenarioGoal;
  String? sessionId;
  String? level;

  CancelToken? _cancel;

  ChatController(this._repo, this.subject) : super(const ChatState());

  void setScenario({String? role, String? goal}) {
    scenarioRole = role;
    scenarioGoal = goal;
  }

  void setSessionId(String? id) {
    sessionId = id;
  }

  void setLevel(String? l) {
    level = l;
  }

  /// Cancels the currently streaming request (if any).
  void stop() {
    try {
      _cancel?.cancel('stopped_by_user');
    } catch (_) {}
    // Commit whatever was streamed so far as the assistant reply
    if (state.streamingText.trim().isNotEmpty) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(role: 'assistant', content: state.streamingText),
        ],
        sending: false,
        streamingText: '',
      );
    } else {
      state = state.copyWith(sending: false, streamingText: '');
    }
  }

  Future<void> send(String userText) async {
    if (userText.trim().isEmpty || state.sending) return;
    final updated = [
      ...state.messages,
      ChatMessage(role: 'user', content: userText),
    ];
    state = state.copyWith(
      messages: updated,
      sending: true,
      error: null,
      streamingText: '',
    );

    _cancel = CancelToken();
    try {
      var acc = '';
      await for (final ev in _repo.stream(
        subject: subject,
        messages: updated,
        level: level,
        scenarioRole: scenarioRole,
        scenarioGoal: scenarioGoal,
        sessionId: sessionId,
        cancelToken: _cancel,
      )) {
        if (ev.error != null) {
          throw Exception(ev.error);
        }
        if (ev.delta != null) {
          acc += ev.delta!;
          state = state.copyWith(streamingText: acc);
        }
        if (ev.done) {
          state = state.copyWith(
            messages: acc.isNotEmpty
                ? [...updated, ChatMessage(role: 'assistant', content: acc)]
                : updated,
            sending: false,
            streamingText: '',
          );
          return;
        }
      }
      // Stream ended without explicit done
      state = state.copyWith(
        messages: acc.isNotEmpty
            ? [...updated, ChatMessage(role: 'assistant', content: acc)]
            : updated,
        sending: false,
        streamingText: '',
      );
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        // Already handled in stop()
        return;
      }
      state = state.copyWith(
        sending: false,
        error: friendlyError(e),
        streamingText: '',
      );
    } finally {
      _cancel = null;
    }
  }

  void appendUserMessage(ChatMessage msg) {
    state = state.copyWith(messages: [...state.messages, msg]);
  }

  void appendAssistantMessage(String text) {
    state = state.copyWith(messages: [
      ...state.messages,
      ChatMessage(role: 'assistant', content: text),
    ]);
  }

  @override
  void dispose() {
    try {
      _cancel?.cancel();
    } catch (_) {}
    super.dispose();
  }
}

final chatControllerProvider = StateNotifierProvider.family<ChatController,
    ChatState, String>((ref, subject) {
  return ChatController(ref.watch(chatRepositoryProvider), subject);
});
