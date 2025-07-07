import 'package:driver/presentation/notifiers/router_notifier.dart';
import 'package:driver/presentation/providers/auth_provider.dart';
import 'package:driver/presentation/providers/driver_provider.dart';
import 'package:driver/presentation/screens/onboarding_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth_screen.dart';
import '../../skeleton.dart';

/// The main app router provider
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = GoRouterRefreshNotifier(ref);
  final onboardingState = ref.watch(onboardingProvider);
  final isOnboardingComplete = onboardingState.isComplete;

  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '/onboarding',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final driver = ref.read(driverProvider);
      final goingToOnboarding = state.uri.path == '/onboarding';
      final loggedIn = driver.driver != null && driver.token != null;
      final isAtAuth = state.matchedLocation == '/auth';
      final isAtHome = state.matchedLocation == '/home';

      // 1. Force onboarding if not complete
      if (!isOnboardingComplete) {
        return goingToOnboarding ? null : '/onboarding';
      }

      // If not logged in and trying to access anything other than /auth, redirect to /auth
      if (!loggedIn && !isAtAuth) {
        return '/auth';
      }

    // If logged in and trying to access /auth, redirect to /home
      if (loggedIn && isAtAuth) {
        return '/home';
      }

      // If logged out and currently at /home, redirect to /auth
      if (!loggedIn && isAtHome) {
        return '/auth';
      }
      return null; // no redirect needed
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const Skeleton(),
      ),
    ],
  );
});
