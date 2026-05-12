import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  StreamSubscription<AuthState>? _sub;

  AuthController() : super(const AuthState()) {
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
      state = state.copyWith(loading: false, error: e.message);
    }
  }

  Future<void> signUp(String email, String password) async {
    if (!AppConfig.supabaseConfigured) {
      state = state.copyWith(error: 'Supabase kalitlari sozlanmagan');
      return;
    }
    state = state.copyWith(loading: true, error: null);
    try {
      await Supabase.instance.client.auth
          .signUp(email: email.trim(), password: password);
      state = state.copyWith(loading: false);
    } on AuthException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    }
  }

  Future<void> signOut() async {
    if (!AppConfig.supabaseConfigured) return;
    await Supabase.instance.client.auth.signOut();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController();
});
