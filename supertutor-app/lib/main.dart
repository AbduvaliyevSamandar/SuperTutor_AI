import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/api_client.dart';
import 'core/config.dart';
import 'core/fcm_service.dart';
import 'core/notifications.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'core/version_check.dart';
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

  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('[Firebase.init] $e');
    }
  }

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
    try {
      await FcmService.init();
    } catch (_) {}
  }));
  FlutterNativeSplash.remove();
  runApp(ProviderScope(child: SuperTutorApp(onboarded: onboarded)));
}

class SuperTutorApp extends ConsumerStatefulWidget {
  final bool onboarded;
  const SuperTutorApp({super.key, required this.onboarded});

  @override
  ConsumerState<SuperTutorApp> createState() => _SuperTutorAppState();
}

class _SuperTutorAppState extends ConsumerState<SuperTutorApp> {
  bool _checkedVersion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowUpdate());
  }

  Future<void> _maybeShowUpdate() async {
    if (_checkedVersion) return;
    _checkedVersion = true;
    try {
      final dio = ref.read(dioProvider);
      final result = await checkVersion(dio);
      if (result == null) return;
      final ctx = ref.read(routerProvider).routerDelegate.navigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      await showUpdateDialog(ctx, result.info, force: result.mode == 'force');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsControllerProvider);
    if (!widget.onboarded) {
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
