import 'dart:async';

import 'package:flutter/foundation.dart';
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

  // Global error handlers — silently log instead of red-screen overlay
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[PlatformError] $error\n$stack');
    return true;
  };

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}
  if (AppConfig.supabaseConfigured) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('[Supabase.init] $e');
    }
  }
  final onboarded = await onboardingDone();
  try {
    await NotificationService.init();
  } catch (_) {}
  unawaited(Future(() async {
    try {
      await NotificationService.scheduleDailyReminder();
    } catch (_) {}
  }));
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
