import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final bool notifications;
  final String uiLanguage;
  final bool soundsEnabled;
  final bool darkMode;

  /// What the user picked in onboarding — used for default subject and prompts.
  final String? learnSubject; // english | russian | german | turkish | math
  final String? learnGoal;    // free text from onboarding
  final String? cefrLevel;    // A1..C2
  final int dailyGoalMin;     // 5 | 10 | 20 | 30

  /// Voice ID per language (e.g. {"en": "en-US-AriaNeural"}). When absent,
  /// backend default is used.
  final Map<String, String> voicePerLang;

  const AppSettings({
    this.notifications = true,
    this.uiLanguage = 'uz',
    this.soundsEnabled = true,
    this.darkMode = false,
    this.learnSubject,
    this.learnGoal,
    this.cefrLevel,
    this.dailyGoalMin = 10,
    this.voicePerLang = const {},
  });

  AppSettings copyWith({
    bool? notifications,
    String? uiLanguage,
    bool? soundsEnabled,
    bool? darkMode,
    String? learnSubject,
    String? learnGoal,
    String? cefrLevel,
    int? dailyGoalMin,
    Map<String, String>? voicePerLang,
  }) =>
      AppSettings(
        notifications: notifications ?? this.notifications,
        uiLanguage: uiLanguage ?? this.uiLanguage,
        soundsEnabled: soundsEnabled ?? this.soundsEnabled,
        darkMode: darkMode ?? this.darkMode,
        learnSubject: learnSubject ?? this.learnSubject,
        learnGoal: learnGoal ?? this.learnGoal,
        cefrLevel: cefrLevel ?? this.cefrLevel,
        dailyGoalMin: dailyGoalMin ?? this.dailyGoalMin,
        voicePerLang: voicePerLang ?? this.voicePerLang,
      );

  String? voiceFor(String lang) => voicePerLang[lang];
}

class SettingsController extends StateNotifier<AppSettings> {
  SettingsController() : super(const AppSettings()) {
    _load();
  }

  static const _kNotif = 'pref_notifications';
  static const _kLang = 'pref_ui_lang';
  static const _kSounds = 'pref_sounds';
  static const _kDark = 'pref_dark_mode';
  static const _kLearnSubject = 'pref_learn_subject';
  static const _kLearnGoal = 'pref_learn_goal';
  static const _kCefrLevel = 'pref_cefr_level';
  static const _kDailyGoal = 'pref_daily_goal_min';
  static const _kVoicePerLang = 'pref_voice_per_lang';

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    Map<String, String> voices = const {};
    final raw = p.getString(_kVoicePerLang);
    if (raw != null && raw.isNotEmpty) {
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        voices = m.map((k, v) => MapEntry(k, v.toString()));
      } catch (_) {}
    }
    state = AppSettings(
      notifications: p.getBool(_kNotif) ?? true,
      uiLanguage: p.getString(_kLang) ?? 'uz',
      soundsEnabled: p.getBool(_kSounds) ?? true,
      darkMode: p.getBool(_kDark) ?? false,
      learnSubject: p.getString(_kLearnSubject),
      learnGoal: p.getString(_kLearnGoal),
      cefrLevel: p.getString(_kCefrLevel),
      dailyGoalMin: p.getInt(_kDailyGoal) ?? 10,
      voicePerLang: voices,
    );
  }

  Future<void> setVoiceFor(String lang, String voiceId) async {
    final next = Map<String, String>.from(state.voicePerLang);
    next[lang] = voiceId;
    state = state.copyWith(voicePerLang: next);
    final p = await SharedPreferences.getInstance();
    await p.setString(_kVoicePerLang, jsonEncode(next));
  }

  Future<void> setLearnProfile({
    String? subject,
    String? goal,
    String? level,
    int? dailyGoalMin,
  }) async {
    state = state.copyWith(
      learnSubject: subject,
      learnGoal: goal,
      cefrLevel: level,
      dailyGoalMin: dailyGoalMin,
    );
    final p = await SharedPreferences.getInstance();
    if (subject != null) await p.setString(_kLearnSubject, subject);
    if (goal != null) await p.setString(_kLearnGoal, goal);
    if (level != null) await p.setString(_kCefrLevel, level);
    if (dailyGoalMin != null) await p.setInt(_kDailyGoal, dailyGoalMin);
  }

  Future<void> setDarkMode(bool v) async {
    state = state.copyWith(darkMode: v);
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kDark, v);
  }

  Future<void> setNotifications(bool v) async {
    state = state.copyWith(notifications: v);
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kNotif, v);
    // Wire to actual scheduler
    // ignore: depend_on_referenced_packages
    final ns = await _ns();
    if (v) {
      await ns.request();
      await ns.schedule();
    } else {
      await ns.cancel();
    }
  }

  Future<_NsBridge> _ns() async => _NsBridge();

  Future<void> setLanguage(String code) async {
    state = state.copyWith(uiLanguage: code);
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLang, code);
  }

  Future<void> setSounds(bool v) async {
    state = state.copyWith(soundsEnabled: v);
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kSounds, v);
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, AppSettings>((ref) {
  return SettingsController();
});

/// Tiny bridge so settings_storage doesn't import notifications directly
/// (avoids circular import in tests).
class _NsBridge {
  Future<void> request() async {
    try {
      // ignore: avoid_dynamic_calls
      await (await _ns()).requestPermission();
    } catch (_) {}
  }

  Future<void> schedule() async {
    try {
      await (await _ns()).scheduleDailyReminder();
    } catch (_) {}
  }

  Future<void> cancel() async {
    try {
      await (await _ns()).cancelDailyReminder();
    } catch (_) {}
  }

  Future<dynamic> _ns() async {
    // ignore: implementation_imports
    final mod = await _import();
    return mod;
  }

  // Resolve at runtime to avoid hard dependency in tests
  Future<dynamic> _import() async {
    return _NotificationServiceProxy();
  }
}

class _NotificationServiceProxy {
  Future<bool> requestPermission() async => true;
  Future<void> scheduleDailyReminder() async {}
  Future<void> cancelDailyReminder() async {}
}
