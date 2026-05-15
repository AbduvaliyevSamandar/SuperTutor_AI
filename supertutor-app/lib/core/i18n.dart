import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/profile/settings_storage.dart';

/// Tiny in-app i18n. Three locales: uz (default), en, ru.
const _strings = <String, Map<String, String>>{
  // Bottom nav
  'nav.home': {'uz': 'Bosh', 'en': 'Home', 'ru': 'Главная'},
  'nav.learn': {'uz': 'Darslar', 'en': 'Learn', 'ru': 'Уроки'},
  'nav.dictionary': {'uz': 'Lug\'at', 'en': 'Dictionary', 'ru': 'Словарь'},
  'nav.stats': {'uz': 'Statistika', 'en': 'Stats', 'ru': 'Статистика'},
  'nav.profile': {'uz': 'Profil', 'en': 'Profile', 'ru': 'Профиль'},
  // Generic
  'common.continue': {
    'uz': 'Davom etish',
    'en': 'Continue',
    'ru': 'Продолжить'
  },
  'common.cancel': {
    'uz': 'Bekor qilish',
    'en': 'Cancel',
    'ru': 'Отмена'
  },
  'common.save': {'uz': 'Saqlash', 'en': 'Save', 'ru': 'Сохранить'},
  'common.delete': {
    'uz': 'O\'chirish',
    'en': 'Delete',
    'ru': 'Удалить'
  },
  'common.back': {'uz': 'Orqaga', 'en': 'Back', 'ru': 'Назад'},
  'common.next': {
    'uz': 'Keyingisi',
    'en': 'Next',
    'ru': 'Далее'
  },
  'common.finish': {
    'uz': 'Tugatish',
    'en': 'Finish',
    'ru': 'Завершить'
  },
  'common.retry': {
    'uz': 'Qaytadan urinish',
    'en': 'Try again',
    'ru': 'Повторить'
  },
  'common.search': {
    'uz': 'Qidirish',
    'en': 'Search',
    'ru': 'Поиск'
  },
  'common.loading': {
    'uz': 'Yuklanmoqda...',
    'en': 'Loading...',
    'ru': 'Загрузка...'
  },
  // Auth
  'auth.welcome': {
    'uz': 'Xush kelibsiz!',
    'en': 'Welcome!',
    'ru': 'Добро пожаловать!'
  },
  'auth.create_account': {
    'uz': 'Akkaunt yarating',
    'en': 'Create account',
    'ru': 'Создать аккаунт'
  },
  'auth.login': {'uz': 'Kirish', 'en': 'Sign in', 'ru': 'Войти'},
  'auth.signup': {
    'uz': 'Ro\'yxatdan o\'tish',
    'en': 'Sign up',
    'ru': 'Регистрация'
  },
  'auth.email': {'uz': 'Email', 'en': 'Email', 'ru': 'Email'},
  'auth.password': {'uz': 'Parol', 'en': 'Password', 'ru': 'Пароль'},
  'auth.forgot_password': {
    'uz': 'Parolni unutdingizmi?',
    'en': 'Forgot password?',
    'ru': 'Забыли пароль?'
  },
  'auth.guest': {
    'uz': 'Mehmon sifatida davom etish',
    'en': 'Continue as guest',
    'ru': 'Продолжить как гость'
  },
  'auth.have_account': {
    'uz': 'Akkauntim bor',
    'en': 'I have an account',
    'ru': 'У меня есть аккаунт'
  },
  'auth.no_account': {
    'uz': 'Akkaunt yaratish',
    'en': 'Create account',
    'ru': 'Создать аккаунт'
  },
  'auth.subtitle': {
    'uz': 'Bepul AI o\'qituvchi bilan o\'rganishni boshlang',
    'en': 'Start learning with a free AI tutor',
    'ru': 'Начните учиться с бесплатным AI-репетитором'
  },
  // Profile
  'profile.title': {
    'uz': 'Profil',
    'en': 'Profile',
    'ru': 'Профиль'
  },
  'profile.account': {
    'uz': 'Akkaunt',
    'en': 'Account',
    'ru': 'Аккаунт'
  },
  'profile.help': {
    'uz': 'Yordam',
    'en': 'Help',
    'ru': 'Помощь'
  },
  'profile.notifications': {
    'uz': 'Bildirishnomalar',
    'en': 'Notifications',
    'ru': 'Уведомления'
  },
  'profile.sounds': {
    'uz': 'Ovoz effektlari',
    'en': 'Sound effects',
    'ru': 'Звуковые эффекты'
  },
  'profile.language': {
    'uz': 'Interfeys tili',
    'en': 'Interface language',
    'ru': 'Язык интерфейса'
  },
  'profile.dark_mode': {
    'uz': 'Tungi rejim',
    'en': 'Dark mode',
    'ru': 'Тёмный режим'
  },
  'profile.faq': {
    'uz': 'Tez-tez so\'raladigan savollar',
    'en': 'Frequently asked questions',
    'ru': 'Часто задаваемые вопросы'
  },
  'profile.about': {
    'uz': 'SuperTutor haqida',
    'en': 'About SuperTutor',
    'ru': 'О SuperTutor'
  },
  'profile.privacy': {
    'uz': 'Maxfiylik siyosati',
    'en': 'Privacy policy',
    'ru': 'Политика конфиденциальности'
  },
  'profile.sign_out': {
    'uz': 'Chiqish',
    'en': 'Sign out',
    'ru': 'Выйти'
  },
  'profile.edit_name': {
    'uz': 'Ismni o\'zgartirish',
    'en': 'Change name',
    'ru': 'Изменить имя'
  },
  'profile.delete_account': {
    'uz': 'Akkauntni o\'chirish',
    'en': 'Delete account',
    'ru': 'Удалить аккаунт'
  },
  // Stats
  'stats.streak': {'uz': 'Streak', 'en': 'Streak', 'ru': 'Серия'},
  'stats.xp': {'uz': 'XP', 'en': 'XP', 'ru': 'XP'},
  'stats.gems': {'uz': 'Gemma', 'en': 'Gems', 'ru': 'Камни'},
  'stats.daily_goal': {
    'uz': 'Kunlik maqsad',
    'en': 'Daily goal',
    'ru': 'Цель дня'
  },
};

String _lookup(String key, String lang) {
  final m = _strings[key];
  if (m == null) return key;
  return m[lang] ?? m['uz'] ?? key;
}

final localeProvider = Provider<String>((ref) {
  return ref.watch(settingsControllerProvider).uiLanguage;
});

extension I18nContext on WidgetRef {
  String tr(String key) {
    final lang = read(localeProvider);
    return _lookup(key, lang);
  }
}

/// For non-Ref widgets — pass lang directly.
String trFor(String lang, String key) => _lookup(key, lang);
