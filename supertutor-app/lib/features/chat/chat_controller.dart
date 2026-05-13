import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'chat_models.dart';
import 'chat_repository.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool sending;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.sending = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? sending,
    String? error,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        sending: sending ?? this.sending,
        error: error,
      );
}

class ChatController extends StateNotifier<ChatState> {
  final ChatRepository _repo;
  final String subject;

  ChatController(this._repo, this.subject) : super(const ChatState());

  Future<void> send(String userText) async {
    if (userText.trim().isEmpty || state.sending) return;
    final updated = [
      ...state.messages,
      ChatMessage(role: 'user', content: userText),
    ];
    state = state.copyWith(messages: updated, sending: true, error: null);

    try {
      final reply = await _repo.send(subject: subject, messages: updated);
      state = state.copyWith(
        messages: [...updated, ChatMessage(role: 'assistant', content: reply)],
        sending: false,
      );
    } catch (e) {
      state = state.copyWith(sending: false, error: e.toString());
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
}

final chatControllerProvider = StateNotifierProvider.family<ChatController,
    ChatState, String>((ref, subject) {
  return ChatController(ref.watch(chatRepositoryProvider), subject);
});
