import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/driver/presentation/pages/screens/auth/auth_screen.dart';
import '../../features/skeleton/skeleton.dart';
import '../../features/driver/presentation/providers/driver_provider.dart';

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

      final loggedIn = driver.isAuthenticated;
      final loggingIn = state.matchedLocation == '/auth';

      // Redirect to /auth if not logged in
      if (!loggedIn && !loggingIn) return '/auth';

      // Redirect to /home if logged in but on /auth
      if (loggedIn && loggingIn) return '/home';

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
