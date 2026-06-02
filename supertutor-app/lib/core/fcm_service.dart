import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';

/// Handles Firebase Cloud Messaging token registration and foreground messages.
class FcmService {
  FcmService._();

  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(alert: true, badge: true, sound: true);

      final token = await messaging.getToken();
      if (token != null) await _registerToken(token);

      messaging.onTokenRefresh.listen(_registerToken);

      FirebaseMessaging.onMessage.listen((msg) {
        debugPrint('[FCM] foreground: ${msg.notification?.title}');
      });
    } catch (e) {
      debugPrint('[FCM] init error: $e');
    }
  }

  static Future<void> _registerToken(String token) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;
    try {
      final dio = Dio(BaseOptions(
        baseUrl: '${AppConfig.apiBaseUrl}/api/v1',
        connectTimeout: const Duration(seconds: 10),
      ));
      await dio.post(
        '/notifications/register-token',
        data: {'fcm_token': token, 'platform': defaultTargetPlatform.name.toLowerCase()},
        options: Options(headers: {'Authorization': 'Bearer ${session.accessToken}'}),
      );
    } catch (e) {
      debugPrint('[FCM] token register error: $e');
    }
  }
}
