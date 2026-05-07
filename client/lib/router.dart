import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'pages/chat_page.dart';
import 'pages/login_page.dart';
import 'pages/settings_page.dart';
import 'pages/splash_page.dart';
import 'providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/chat',
    refreshListenable: ref.watch(authListenableProvider),
    redirect: (ctx, state) {
      final loggedIn = auth.token != null;
      final loggingIn = state.matchedLocation == '/login';
      final splashing = state.matchedLocation == '/splash';

      if (auth.bootstrapping) return splashing ? null : '/splash';
      // 未登录时不强制跳 login，ChatPage 自己展示「去登录」提示
      if (loggedIn && (loggingIn || splashing)) return '/chat';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/chat', builder: (_, __) => const ChatPage()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
    ],
  );
});
