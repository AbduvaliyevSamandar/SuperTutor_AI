import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import 'chat_models.dart';

class ChatRepository {
  final Dio _dio;
  ChatRepository(this._dio);

  Future<String> send({
    required String subject,
    required List<ChatMessage> messages,
    String? level,
    String? scenarioRole,
    String? scenarioGoal,
  }) async {
    final response = await _dio.post(
      '/chat',
      data: {
        'subject': subject,
        if (level != null) 'level': level,
        if (scenarioRole != null) 'scenario_role': scenarioRole,
        if (scenarioGoal != null) 'scenario_goal': scenarioGoal,
        'messages': messages.map((m) => m.toJson()).toList(),
      },
    );
    return response.data['reply'] as String;
  }

  Future<String> transcribe(List<int> audioBytes,
      {String? language, String filename = 'audio.m4a'}) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(audioBytes, filename: filename),
      if (language != null) 'language': language,
    });
    final response = await _dio.post('/stt', data: form);
    return response.data['text'] as String;
  }

  Future<String> analyzeImage({
    required List<int> imageBytes,
    required String subject,
    String? prompt,
    String filename = 'photo.jpg',
    String mime = 'image/jpeg',
  }) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        imageBytes,
        filename: filename,
        contentType: DioMediaType.parse(mime),
      ),
      'subject': subject,
      if (prompt != null) 'prompt': prompt,
    });
    final r = await _dio.post('/chat-vision', data: form);
    return r.data['reply'] as String;
  }

  Future<Uint8List> synthesize(String text,
      {String language = 'en', String? voice}) async {
    final response = await _dio.post(
      '/tts',
      data: {
        'text': text,
        'language': language,
        if (voice != null) 'voice': voice,
      },
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data as List<int>);
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(dioProvider));
});
