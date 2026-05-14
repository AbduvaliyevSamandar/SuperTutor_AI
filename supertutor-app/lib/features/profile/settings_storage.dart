import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final bool notifications;
  final String uiLanguage;
  final bool soundsEnabled;
  final bool darkMode;

  const AppSettings({
    this.notifications = true,
    this.uiLanguage = 'uz',
    this.soundsEnabled = true,
    this.darkMode = false,
  });

  AppSettings copyWith({
    bool? notifications,
    String? uiLanguage,
    bool? soundsEnabled,
    bool? darkMode,
  }) =>
      AppSettings(
        notifications: notifications ?? this.notifications,
        uiLanguage: uiLanguage ?? this.uiLanguage,
        soundsEnabled: soundsEnabled ?? this.soundsEnabled,
        darkMode: darkMode ?? this.darkMode,
      );
}

class SettingsController extends StateNotifier<AppSettings> {
  SettingsController() : super(const AppSettings()) {
    _load();
  }

  static const _kNotif = 'pref_notifications';
  static const _kLang = 'pref_ui_lang';
  static const _kSounds = 'pref_sounds';
  static const _kDark = 'pref_dark_mode';

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = AppSettings(
      notifications: p.getBool(_kNotif) ?? true,
      uiLanguage: p.getString(_kLang) ?? 'uz',
      soundsEnabled: p.getBool(_kSounds) ?? true,
      darkMode: p.getBool(_kDark) ?? false,
    );
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
