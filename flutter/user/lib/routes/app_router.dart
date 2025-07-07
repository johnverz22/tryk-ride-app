import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/user/presentation/pages/screens/auth/auth_screen.dart';
import '../../features/user/presentation/pages/screens/main_navigation_screen.dart';
import '../../features/user/presentation/pages/screens/onboarding/onboarding_screen.dart';
import '../../features/user/presentation/providers/user_provider.dart';
import '../../features/user/presentation/providers/onboarding_provider.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final userAsync = ref.watch(userProvider);
  final onboardingState = ref.watch(onboardingProvider);
  final isOnboardingComplete = onboardingState.isComplete;

  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '/onboarding',
    routes: [
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
      final goingToOnboarding = state.uri.path == '/onboarding';
      final goingToAuth = state.uri.path == '/auth';

      // ⛔ Wait for userProvider to load
      if (userAsync.isLoading) return null;

      final userState = userAsync.value;

      // 1. Force onboarding if not complete
      if (!isOnboardingComplete) {
        return goingToOnboarding ? null : '/onboarding';
      }

      // 2. If user is not logged in, go to auth
      if (userState == null || !userState.isAuthenticated) {
        return goingToAuth ? null : '/auth';
      }

      // 3. User is authenticated, prevent access to auth/onboarding
      if (goingToAuth || goingToOnboarding) return '/home';

      return null;
    },
  );
});
