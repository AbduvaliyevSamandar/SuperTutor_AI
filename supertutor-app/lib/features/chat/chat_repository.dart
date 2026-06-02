import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import 'chat_models.dart';

class ChatStreamEvent {
  final String? delta;
  final String? provider;
  final bool done;
  final String? error;
  ChatStreamEvent({this.delta, this.provider, this.done = false, this.error});
}

class ChatRepository {
  final Dio _dio;
  ChatRepository(this._dio);

  Future<String> send({
    required String subject,
    required List<ChatMessage> messages,
    String? level,
    String? scenarioRole,
    String? scenarioGoal,
    String? sessionId,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.post(
      '/chat',
      data: {
        'subject': subject,
        if (level != null) 'level': level,
        if (scenarioRole != null) 'scenario_role': scenarioRole,
        if (scenarioGoal != null) 'scenario_goal': scenarioGoal,
        if (sessionId != null) 'session_id': sessionId,
        'messages': messages.map((m) => m.toJson()).toList(),
      },
      cancelToken: cancelToken,
    );
    return response.data['reply'] as String;
  }

  /// Streams the assistant reply chunk-by-chunk via Server-Sent Events.
  /// Falls back to non-streaming `send()` if the stream connection fails before
  /// any delta arrives.
  Stream<ChatStreamEvent> stream({
    required String subject,
    required List<ChatMessage> messages,
    String? level,
    String? scenarioRole,
    String? scenarioGoal,
    String? sessionId,
    CancelToken? cancelToken,
  }) async* {
    final body = {
      'subject': subject,
      if (level != null) 'level': level,
      if (scenarioRole != null) 'scenario_role': scenarioRole,
      if (scenarioGoal != null) 'scenario_goal': scenarioGoal,
      if (sessionId != null) 'session_id': sessionId,
      'messages': messages.map((m) => m.toJson()).toList(),
    };

    Response<ResponseBody>? response;
    try {
      response = await _dio.post<ResponseBody>(
        '/chat/stream',
        data: body,
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
        ),
        cancelToken: cancelToken,
      );
    } catch (e) {
      // Stream open failed — fall back to non-streaming
      try {
        final reply = await send(
          subject: subject,
          messages: messages,
          level: level,
          scenarioRole: scenarioRole,
          scenarioGoal: scenarioGoal,
          sessionId: sessionId,
          cancelToken: cancelToken,
        );
        yield ChatStreamEvent(delta: reply);
        yield ChatStreamEvent(done: true);
      } catch (e2) {
        yield ChatStreamEvent(error: e2.toString());
      }
      return;
    }

    var buffer = '';
    try {
      await for (final raw in response.data!.stream) {
        buffer += utf8.decode(raw, allowMalformed: true);
        while (true) {
          final idx = buffer.indexOf('\n\n');
          if (idx < 0) break;
          final block = buffer.substring(0, idx);
          buffer = buffer.substring(idx + 2);
          for (final line in block.split('\n')) {
            if (!line.startsWith('data:')) continue;
            final payload = line.substring(5).trim();
            if (payload.isEmpty) continue;
            try {
              final m = jsonDecode(payload) as Map<String, dynamic>;
              if (m['error'] != null) {
                yield ChatStreamEvent(error: m['error'] as String);
                return;
              }
              if (m['done'] == true) {
                yield ChatStreamEvent(
                  done: true,
                  provider: m['provider'] as String?,
                );
                return;
              }
              final delta = m['delta'] as String?;
              if (delta != null && delta.isNotEmpty) {
                yield ChatStreamEvent(
                  delta: delta,
                  provider: m['provider'] as String?,
                );
              }
            } catch (_) {
              // Skip malformed chunks
            }
          }
        }
      }
      yield ChatStreamEvent(done: true);
    } catch (e) {
      yield ChatStreamEvent(error: e.toString());
    }
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

  /// Pre-warms the backend LLM provider connection. Fire-and-forget.
  Future<void> warmup() async {
    try {
      await _dio.get('/chat/warmup',
          options: Options(receiveTimeout: const Duration(seconds: 5)));
    } catch (_) {}
    // Avoid analyzer "unused" warning if AppConfig isn't referenced elsewhere
    AppConfig.apiBaseUrl;
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(dioProvider));
});
