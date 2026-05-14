import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';

class AuthState {
  final Session? session;
  final bool loading;
  final String? error;

  const AuthState({this.session, this.loading = false, this.error});

  bool get isAuthenticated => session != null;

  AuthState copyWith({Session? session, bool? loading, String? error}) =>
      AuthState(
        session: session ?? this.session,
        loading: loading ?? this.loading,
        error: error,
      );
}

class AuthController extends StateNotifier<AuthState> {
  final Dio _dio;
  StreamSubscription<AuthState>? _sub;

  AuthController(this._dio) : super(const AuthState()) {
    if (!AppConfig.supabaseConfigured) return;
    final client = Supabase.instance.client;
    state = AuthState(session: client.auth.currentSession);
    client.auth.onAuthStateChange.listen((data) {
      state = state.copyWith(session: data.session, error: null);
    });
  }

  Future<void> signIn(String email, String password) async {
    final em = email.trim();
    if (em.isEmpty || password.length < 4) {
      state = state.copyWith(error: 'Email va parolni to\'liq kiriting');
      return;
    }
    if (!AppConfig.supabaseConfigured) {
      state = state.copyWith(error: 'Supabase kalitlari sozlanmagan');
      return;
    }
    state = state.copyWith(loading: true, error: null);
    try {
      await Supabase.instance.client.auth
          .signInWithPassword(email: em, password: password);
      state = state.copyWith(loading: false);
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('email') &&
          (msg.contains('not confirmed') || msg.contains('not_confirmed'))) {
        try {
          await _dio.post('/auth/ensure-confirmed', data: {'email': em});
          await Supabase.instance.client.auth
              .signInWithPassword(email: em, password: password);
          state = state.copyWith(loading: false);
          return;
        } catch (_) {}
      }
      state = state.copyWith(loading: false, error: _humanize(e.message));
    } catch (e) {
      state = state.copyWith(loading: false, error: _humanize(e.toString()));
    }
  }

  /// Returns null on success, error message on failure.
  Future<String?> resetPassword(String email, String newPassword) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _dio.post('/auth/reset-password', data: {
        'email': email.trim(),
        'new_password': newPassword,
      });
      state = state.copyWith(loading: false);
      return null;
    } on DioException catch (e) {
      final detail = (e.response?.data is Map)
          ? (e.response!.data['detail']?.toString() ?? e.message ?? 'Xato')
          : (e.message ?? 'Xato');
      state = state.copyWith(loading: false, error: detail);
      return detail;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return e.toString();
    }
  }

  /// Signup goes through backend /auth/signup which auto-confirms the user,
  /// then we sign in immediately so no email verification step is needed.
  Future<void> signUp(String email, String password,
      {String? displayName}) async {
    final em = email.trim();
    if (em.isEmpty || !em.contains('@')) {
      state = state.copyWith(error: 'To\'g\'ri email kiriting');
      return;
    }
    if (password.length < 6) {
      state = state.copyWith(error: 'Parol kamida 6 ta belgi bo\'lsin');
      return;
    }
    if (!AppConfig.supabaseConfigured) {
      state = state.copyWith(error: 'Supabase kalitlari sozlanmagan');
      return;
    }
    state = state.copyWith(loading: true, error: null);
    try {
      await _dio.post('/auth/signup', data: {
        'email': em,
        'password': password,
        if (displayName != null && displayName.isNotEmpty)
          'display_name': displayName,
      });
      await Supabase.instance.client.auth
          .signInWithPassword(email: em, password: password);
      state = state.copyWith(loading: false);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final detail = _extractError(e);
      if (status == 409) {
        state = state.copyWith(
            loading: false, error: 'Bu email allaqachon ro\'yxatdan o\'tgan');
      } else if (status == 503 || status == 502) {
        state = state.copyWith(
            loading: false,
            error: 'Server uyg\'onmoqda, 30 soniyadan keyin urinib ko\'ring');
      } else {
        state = state.copyWith(loading: false, error: detail);
      }
    } on AuthException catch (e) {
      state = state.copyWith(loading: false, error: _humanize(e.message));
    } catch (e) {
      state = state.copyWith(loading: false, error: _humanize(e.toString()));
    }
  }

  String _extractError(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map && data['detail'] != null) {
        return data['detail'].toString();
      }
    } catch (_) {}
    return e.message ?? 'Tarmoq xatosi';
  }

  Future<void> signInWithGoogle() async {
    if (!AppConfig.supabaseConfigured) {
      state = state.copyWith(error: 'Supabase kalitlari sozlanmagan');
      return;
    }
    state = state.copyWith(loading: true, error: null);
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: AppConfig.googleRedirectUrl,
      );
      state = state.copyWith(loading: false);
    } on AuthException catch (e) {
      state = state.copyWith(loading: false, error: _humanize(e.message));
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> signOut() async {
    if (!AppConfig.supabaseConfigured) return;
    await Supabase.instance.client.auth.signOut();
  }

  String _humanize(String msg) {
    final m = msg.toLowerCase();
    if (m.contains('invalid login') || m.contains('credentials')) {
      return 'Email yoki parol noto\'g\'ri';
    }
    if (m.contains('email not confirmed')) return 'Email tasdiqlanmagan';
    if (m.contains('user already')) return 'Bu email allaqachon ishlatilgan';
    if (m.contains('password should')) return 'Parol kamida 6 ta belgi bo\'lsin';
    if (m.contains('rate limit')) return 'Juda ko\'p urinish — biroz kuting';
    if (m.contains('network') ||
        m.contains('socket') ||
        m.contains('timeout') ||
        m.contains('connection')) {
      return 'Internet aloqasi sekin. Qaytadan urinib ko\'ring.';
    }
    if (m.contains('database error')) {
      return 'Server vaqtinchalik xato. Qaytadan urinib ko\'ring.';
    }
    return msg.length > 100 ? msg.substring(0, 100) : msg;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(dioProvider));
});
