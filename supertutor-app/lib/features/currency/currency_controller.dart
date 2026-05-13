import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../auth/auth_controller.dart';
import 'currency_models.dart';

class CurrencyRepository {
  final Dio _dio;
  CurrencyRepository(this._dio);

  Future<CurrencyState> me() async {
    final r = await _dio.get('/currency/me');
    return CurrencyState.fromJson(Map<String, dynamic>.from(r.data));
  }

  Future<CurrencyState> loseHeart() async {
    final r = await _dio.post('/currency/lose-heart');
    return CurrencyState.fromJson(Map<String, dynamic>.from(r.data));
  }

  Future<CurrencyState> refillHearts() async {
    final r = await _dio.post('/currency/refill-hearts');
    return CurrencyState.fromJson(Map<String, dynamic>.from(r.data));
  }

  Future<Map<String, dynamic>> awardXp(int xp, {String? reason}) async {
    final r = await _dio.post('/currency/award-xp', data: {
      'xp': xp,
      if (reason != null) 'reason': reason,
    });
    return Map<String, dynamic>.from(r.data);
  }

  Future<CurrencyState> setGoal(int targetXp) async {
    final r =
        await _dio.post('/currency/set-goal', data: {'target_xp': targetXp});
    return CurrencyState.fromJson(Map<String, dynamic>.from(r.data));
  }
}

final currencyRepositoryProvider = Provider<CurrencyRepository>((ref) {
  return CurrencyRepository(ref.watch(dioProvider));
});

class CurrencyController extends StateNotifier<CurrencyState?> {
  final CurrencyRepository _repo;
  CurrencyController(this._repo) : super(null);

  Future<void> refresh() async {
    try {
      state = await _repo.me();
    } catch (_) {
      // Stay with whatever state we have; failing silently is fine for a chip.
    }
  }

  /// Returns false if user is out of hearts.
  Future<bool> loseHeart() async {
    try {
      state = await _repo.loseHeart();
      return state!.hearts >= 0;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        return false;
      }
      rethrow;
    }
  }

  Future<bool> refillHearts() async {
    try {
      state = await _repo.refillHearts();
      return true;
    } on DioException {
      return false;
    }
  }

  /// Returns true when the daily goal was reached on this call.
  Future<bool> awardXp(int xp, {String? reason}) async {
    final result = await _repo.awardXp(xp, reason: reason);
    final reached = result['daily_goal_reached'] == true;
    // Optimistic local update
    final s = state;
    if (s != null) {
      state = s.copyWith(
        xpTotal: result['xp_total'] ?? s.xpTotal + xp,
        dailyEarnedXp: result['daily_earned_xp'] ?? s.dailyEarnedXp + xp,
        dailyTargetXp: result['daily_target_xp'] ?? s.dailyTargetXp,
      );
    }
    return reached;
  }

  Future<void> setGoal(int targetXp) async {
    state = await _repo.setGoal(targetXp);
  }
}

final currencyControllerProvider =
    StateNotifierProvider<CurrencyController, CurrencyState?>((ref) {
  final ctrl = CurrencyController(ref.watch(currencyRepositoryProvider));
  ref.listen<AuthState>(authControllerProvider, (prev, next) {
    if (next.isAuthenticated && prev?.session?.user.id != next.session?.user.id) {
      ctrl.refresh();
    }
  });
  // Initial load if already signed in
  if (ref.read(authControllerProvider).isAuthenticated) {
    ctrl.refresh();
  }
  return ctrl;
});
