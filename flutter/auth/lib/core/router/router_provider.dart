import 'package:auth/features/auth/presentation/providers/auth_providers.dart';
import 'package:auth/features/home/presentation/screens/home_screen.dart';
import 'package:auth/features/home/presentation/screens/skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isOnSplash = state.matchedLocation == '/splash';
      final isOnLogin = state.matchedLocation == '/login';
      final isOnRegister = state.matchedLocation == '/register';

      return authState.when(
        initial: () => isOnSplash ? null : '/splash',
        loading: () => isOnSplash ? null : '/splash',
        authenticated: (user) =>
            (isOnLogin || isOnRegister || isOnSplash) ? '/home' : null,
        unauthenticated: () => (isOnLogin || isOnRegister) ? null : '/login',
        error: (failure) {
          if (isOnLogin) {
            return null;
          }

          if (isOnRegister) {
            return '/register';
          }

          return '/login';
        },
      );
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const Skeleton()),
    ],
  );
});
