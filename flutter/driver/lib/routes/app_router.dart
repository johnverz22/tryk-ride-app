import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/driver/presentation/pages/screens/auth/auth_screen.dart';
import '../../features/driver/presentation/pages/screens/main_navigation_screen.dart';
import '../../features/driver/presentation/pages/screens/onboarding_screen.dart';
import '../../features/driver/presentation/pages/screens/splash_screen.dart';
import '../../features/driver/presentation/providers/driver_provider.dart';
import '../../features/driver/presentation/providers/shared_preferences_provider.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final userAsync = ref.watch(driverProvider);
  final onboardingAsync = ref.watch(onboardingProvider);

  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) =>
            const MainNavigationScreen(initialIndex: 0),
        routes: [
          GoRoute(
            path: 'trips',
            name: 'trips',
            builder: (context, state) =>
                const MainNavigationScreen(initialIndex: 1),
          ),
          GoRoute(
            path: 'earnings',
            name: 'earnings',
            builder: (context, state) =>
                const MainNavigationScreen(initialIndex: 2),
          ),
          GoRoute(
            path: 'dashboard',
            name: 'dashboard',
            builder: (context, state) =>
                const MainNavigationScreen(initialIndex: 3),
          ),
          GoRoute(
            path: 'profile',
            name: 'profile',
            builder: (context, state) =>
                const MainNavigationScreen(initialIndex: 4),
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final location = state.uri.path;

      final goingToAuth = location == '/auth';
      final goingToOnboarding = location == '/onboarding';
      final isSplash = location == '/';

      // Wait for async providers to resolve
      if (userAsync.isLoading || onboardingAsync.isLoading) return null;

      final user = userAsync.value;
      final onboardingComplete = onboardingAsync.value ?? false;

      // 1. Redirect to onboarding if not complete
      if (!onboardingComplete && !goingToOnboarding) {
        return '/onboarding';
      }

      // 2. Onboarding complete, but not authenticated
      if (onboardingComplete && (user == null || !user.isAuthenticated)) {
        if (!goingToAuth) return '/auth';
      }

      // 3. Authenticated user trying to access splash, auth, or onboarding
      final isPublic = isSplash || goingToAuth || goingToOnboarding;
      final isAuthenticated = user?.isAuthenticated == true;

      if (isAuthenticated && isPublic) {
        return '/home';
      }

      // 4. Everything else is fine
      return null;
    },
  );
});
