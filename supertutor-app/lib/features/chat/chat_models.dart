class ChatMessage {
  final String role;
  final String content;
  final List<int>? imageBytes;
  ChatMessage({required this.role, required this.content, this.imageBytes});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}
