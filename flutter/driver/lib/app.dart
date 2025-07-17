import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/theme.dart';
import 'routes/app_router.dart';
import 'features/driver/presentation/providers/driver_provider.dart';

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(driverProvider);

    return userAsync.when(
      loading: () => _buildLoadingScreen(),
      error: (err, _) => _buildErrorScreen(err),
      data: (_) {
        final router = ref.watch(goRouterProvider);
        return MaterialApp.router(
          routerConfig: router,
          theme: appTheme,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }

  Widget _buildLoadingScreen() => const MaterialApp(
    home: Scaffold(body: Center(child: CircularProgressIndicator())),
    debugShowCheckedModeBanner: false,
  );

  Widget _buildErrorScreen(Object error) => MaterialApp(
    home: Scaffold(body: Center(child: Text('Error: $error'))),
    debugShowCheckedModeBanner: false,
  );
}
