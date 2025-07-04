import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/user/presentation/pages/screens/auth/auth_screen.dart';
import '../../features/user/presentation/pages/screens/main_navigation_screen.dart';
import '../../features/user/presentation/pages/screens/onboarding/onboarding_screen.dart';
import '../../features/user/presentation/providers/user_provider.dart';
import '../../features/user/presentation/providers/onboarding_provider.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final user = ref.watch(userProvider).value;
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

      if (!isOnboardingComplete) {
        return goingToOnboarding ? null : '/onboarding';
      }

      if (user == null) {
        return goingToAuth ? null : '/auth';
      }

      // If user is authenticated, redirect to /auth instead of /home
      if (goingToAuth) return null; // allow /auth route
      return '/auth';
    },
  );
});
