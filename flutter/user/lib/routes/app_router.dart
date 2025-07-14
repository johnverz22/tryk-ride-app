import 'package:user/features/profile/presentation/providers/shared_preferences_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/profile/presentation/pages/screens/auth/auth_screen.dart';
import '../features/profile/presentation/pages/screens/main_navigation_screen.dart';
import '../features/profile/presentation/pages/screens/onboarding_screen.dart';
import '../features/profile/presentation/pages/screens/splash_screen.dart';
import '../features/profile/presentation/providers/user_provider.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final userAsync = ref.watch(userProvider);
  final onboardingAsync = ref.watch(onboardingProvider);

  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainNavigationScreen(),
      ),
    ],
    redirect: (context, state) {
      final location = state.uri.path;

      final goingToAuth = location == '/auth';
      final goingToOnboarding = location == '/onboarding';
      final isSplash = location == '/';

      // Wait until both async values are ready
      if (userAsync.isLoading || onboardingAsync.isLoading) return null;

      final userState = userAsync.value;
      final onboardingComplete = onboardingAsync.value ?? false;

      // 1. Go to onboarding if not completed
      if (!onboardingComplete && !goingToOnboarding) {
        return '/onboarding';
      }

      // 2. Onboarding done but user not logged in
      if (onboardingComplete &&
          (userState == null || !userState.isAuthenticated)) {
        if (!goingToAuth) return '/auth';
      }

      // 3. Authenticated users should not access auth/onboarding/splash
      if (userState?.isAuthenticated == true) {
        if (goingToAuth || goingToOnboarding || isSplash) {
          return '/home';
        }
      }

      // 4. If everything matches, stay
      return null;
    },
  );
});
