import 'package:driver/presentation/providers/driver_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/auth_screen.dart';
import '../../skeleton.dart';

/// Notifies GoRouter when driverProvider changes (auth/login/logout)
class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(this.ref) {
    ref.listen(driverProvider, (_, _) => notifyListeners());
  }

  final Ref ref;
}

/// The main app router provider
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = GoRouterRefreshNotifier(ref);

  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '/auth',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final driver = ref.read(driverProvider);

      final loggedIn = driver.driver != null && driver.token != null;
      final isAtAuth = state.matchedLocation == '/auth';
      final isAtHome = state.matchedLocation == '/home';

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
