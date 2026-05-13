class CurrencyState {
  final int hearts;
  final int maxHearts;
  final int xpTotal;
  final int gems;
  final int streakFreezes;
  final int nextHeartInSeconds;
  final int dailyTargetXp;
  final int dailyEarnedXp;

  const CurrencyState({
    this.hearts = 5,
    this.maxHearts = 5,
    this.xpTotal = 0,
    this.gems = 50,
    this.streakFreezes = 0,
    this.nextHeartInSeconds = 0,
    this.dailyTargetXp = 20,
    this.dailyEarnedXp = 0,
  });

  bool get dailyGoalReached => dailyEarnedXp >= dailyTargetXp;
  double get dailyProgress =>
      dailyTargetXp == 0 ? 0 : (dailyEarnedXp / dailyTargetXp).clamp(0.0, 1.0);

  factory CurrencyState.fromJson(Map<String, dynamic> j) => CurrencyState(
        hearts: j['hearts'] ?? 5,
        maxHearts: j['max_hearts'] ?? 5,
        xpTotal: j['xp_total'] ?? 0,
        gems: j['gems'] ?? 50,
        streakFreezes: j['streak_freezes'] ?? 0,
        nextHeartInSeconds: j['next_heart_in_seconds'] ?? 0,
        dailyTargetXp: j['daily_target_xp'] ?? 20,
        dailyEarnedXp: j['daily_earned_xp'] ?? 0,
      );

  CurrencyState copyWith({
    int? hearts,
    int? xpTotal,
    int? gems,
    int? nextHeartInSeconds,
    int? dailyTargetXp,
    int? dailyEarnedXp,
  }) =>
      CurrencyState(
        hearts: hearts ?? this.hearts,
        maxHearts: maxHearts,
        xpTotal: xpTotal ?? this.xpTotal,
        gems: gems ?? this.gems,
        streakFreezes: streakFreezes,
        nextHeartInSeconds: nextHeartInSeconds ?? this.nextHeartInSeconds,
        dailyTargetXp: dailyTargetXp ?? this.dailyTargetXp,
        dailyEarnedXp: dailyEarnedXp ?? this.dailyEarnedXp,
      );
}
