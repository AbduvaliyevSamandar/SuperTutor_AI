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
  }) async {
    final response = await _dio.post(
      '/chat',
      data: {
        'subject': subject,
        if (level != null) 'level': level,
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
