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
  }

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
