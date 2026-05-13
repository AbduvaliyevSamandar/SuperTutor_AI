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
    if (!AppConfig.supabaseConfigured) {
      state = state.copyWith(error: 'Supabase kalitlari sozlanmagan');
      return;
    }
    state = state.copyWith(loading: true, error: null);
    try {
      await Supabase.instance.client.auth
          .signInWithPassword(email: email.trim(), password: password);
      state = state.copyWith(loading: false);
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      // Auto-recover pre-existing accounts whose email confirmation was never sent.
      if (msg.contains('email') &&
          (msg.contains('not confirmed') || msg.contains('not_confirmed'))) {
        try {
          await _dio.post('/auth/ensure-confirmed', data: {'email': email.trim()});
          await Supabase.instance.client.auth
              .signInWithPassword(email: email.trim(), password: password);
          state = state.copyWith(loading: false);
          return;
        } catch (_) {}
      }
      state = state.copyWith(loading: false, error: _humanize(e.message));
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
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
    if (!AppConfig.supabaseConfigured) {
      state = state.copyWith(error: 'Supabase kalitlari sozlanmagan');
      return;
    }
    state = state.copyWith(loading: true, error: null);
    try {
      await _dio.post('/auth/signup', data: {
        'email': email.trim(),
        'password': password,
        if (displayName != null && displayName.isNotEmpty)
          'display_name': displayName,
      });
      await Supabase.instance.client.auth
          .signInWithPassword(email: email.trim(), password: password);
      state = state.copyWith(loading: false);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final detail = (e.response?.data is Map)
          ? (e.response!.data['detail']?.toString() ?? e.message)
          : (e.message ?? 'Network error');
      if (status == 409) {
        state = state.copyWith(
            loading: false, error: 'Bu email allaqachon ro\'yxatdan o\'tgan');
      } else {
        state = state.copyWith(loading: false, error: detail);
      }
    } on AuthException catch (e) {
      state = state.copyWith(loading: false, error: _humanize(e.message));
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
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
    if (m.contains('invalid login')) return 'Email yoki parol noto\'g\'ri';
    if (m.contains('email not confirmed')) return 'Email tasdiqlanmagan';
    if (m.contains('user already')) return 'Bu email allaqachon ishlatilgan';
    if (m.contains('password should')) return 'Parol kamida 6 ta belgi bo\'lsin';
    return msg;
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
