import 'package:go_router/go_router.dart';

import '../features/auth/login_screen.dart';
import '../features/home/home_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/dashboard/dashboard_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(
      path: '/chat/:subject',
      builder: (_, state) => ChatScreen(
        subject: state.pathParameters['subject'] ?? 'english',
      ),
    ),
    GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
  ],
);
