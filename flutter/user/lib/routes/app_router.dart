import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/user/presentation/pages/screens/auth/auth_screen.dart';
import '../../features/user/presentation/pages/screens/main_navigation_screen.dart';
import '../../features/user/presentation/providers/user_provider.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final user = ref.watch(userProvider).value;

  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: user?.isAuthenticated == true ? '/home' : '/auth',
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainNavigationScreen(),
      ),
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
    ],
    redirect: (context, state) {
      if (user == null) return '/auth';
      return null;
    },
  );
});
