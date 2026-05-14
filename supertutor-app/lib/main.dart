import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config.dart';
import 'core/notifications.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/profile/settings_storage.dart';
import 'widgets/warmup_overlay.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env missing is fine in dev
  }
  if (AppConfig.supabaseConfigured) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }
  final onboarded = await onboardingDone();
  await NotificationService.init();
  // Schedule the daily reminder (no-op if pref disabled). Permission is
  // requested lazily the first time user toggles it in settings.
  unawaited(NotificationService.scheduleDailyReminder());
  FlutterNativeSplash.remove();
  runApp(ProviderScope(child: SuperTutorApp(onboarded: onboarded)));
}

class SuperTutorApp extends ConsumerWidget {
  final bool onboarded;
  const SuperTutorApp({super.key, required this.onboarded});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsControllerProvider);
    if (!onboarded) {
      router.go('/onboarding');
    }
    return MaterialApp.router(
      title: 'SuperTutor AI',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      builder: (context, child) => WarmupGate(child: child ?? const SizedBox()),
    );
  }
}
