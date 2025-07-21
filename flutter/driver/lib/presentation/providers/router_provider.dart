import 'package:driver/core/providers/shared_prefs_provider.dart';
import 'package:driver/presentation/notifiers/router_notifier.dart';
import 'package:driver/presentation/providers/driver_provider.dart';
import 'package:driver/presentation/screens/onboarding_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/auth_screen.dart';
import '../../skeleton.dart';

/// The main app router provider
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = GoRouterRefreshNotifier(ref);
  final user = ref.watch(driverProvider);
  final onboarded = ref.read(sharedPrefsProvider).getOnboarding();

  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '/home',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final location = state.uri.path;

      final goingToAuth = location == '/auth';
      final goingToOnboarding = location == '/onboarding';
      final isSplash = location == '/';
      final isAtHome = location == '/home';

      // 1. Go to onboarding if not completed
      if (!onboarded && !goingToOnboarding) {
        return '/onboarding';
      }

      // 2. Onboarding done but user not logged in
      if (onboarded && (user.driver == null || !user.isAuthenticated)) {
        if (!goingToAuth) return '/auth';
      }

      // 3. User is authenticated but going to onboarding or auth
      if (user.isAuthenticated == true &&
          (goingToAuth || goingToOnboarding || isSplash)) {
        if (!isAtHome) return '/home';
      }

      // 4. If everything matches, stay
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(path: '/home', builder: (context, state) => const Skeleton()),
    ],
  );
});

//TODO: Isolate the auth first
