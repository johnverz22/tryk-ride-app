import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/theme.dart';
import 'routes/app_router.dart';
import 'features/profile/presentation/providers/user_provider.dart';

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final router = ref.watch(goRouterProvider);

    // The location check is removed from here for a faster startup.
    return userAsync.when(
      loading: () => _buildLoadingScreen(message: "Loading user data..."),
      error: (err, _) => _buildErrorScreen(err),
      data: (_) {
        // Once user data is available, show the app.
        // Location will be fetched in the background on the HomeScreen.
        return MaterialApp.router(
          routerConfig: router,
          theme: appTheme,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }

  Widget _buildLoadingScreen({String message = "Loading..."}) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    ),
    debugShowCheckedModeBanner: false,
  );

  Widget _buildErrorScreen(Object error) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text(
                'App Error: ${error.toString()}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    ),
    debugShowCheckedModeBanner: false,
  );
}
