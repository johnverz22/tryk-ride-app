import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'config/theme.dart';
import 'routes/app_router.dart';
import 'features/driver/presentation/providers/driver_provider.dart';
import 'providers/initial_location_provider.dart';

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverAsync = ref.watch(driverProvider);
    final initialLocationAsync = ref.watch(
      initialLocationProvider,
    ); // Watch the new provider

    return driverAsync.when(
      loading: () => _buildLoadingScreen(
        message: "Loading user data...",
      ), // Initial loading for user data
      error: (err, _) => _buildErrorScreen(err),
      data: (_) {
        // Once user data is loaded, check initial location
        return initialLocationAsync.when(
          loading: () => _buildLoadingScreen(
            message: "Detecting your location...",
          ), // Specific loading for location
          error: (err, _) => _buildErrorScreen(
            err,
            locationError: true,
          ), // Handle location specific errors
          data: (initialLatLng) {
            // Pass the initialLatLng to your router or directly to the LocationPickerScreen
            final router = ref.watch(goRouterProvider);
            return MaterialApp.router(
              routerConfig: router,
              theme: appTheme,
              debugShowCheckedModeBanner: false,
              // You might need to pass initialLatLng to your router's extra parameter
              // or directly to the LocationPickerScreen if it's the root.
              // For GoRouter, you can use extra: initialLatLng in your route definition.
            );
          },
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

  Widget _buildErrorScreen(Object error, {bool locationError = false}) =>
      MaterialApp(
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
                    locationError
                        ? 'Location Error: ${error.toString()}'
                        : 'App Error: ${error.toString()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, color: Colors.red),
                  ),
                  if (locationError) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Guide user to app settings for location permission
                        Permission.location.request().then((status) {
                          if (status.isPermanentlyDenied) {
                            openAppSettings();
                          }
                        });
                      },
                      child: const Text('Grant Location Permission'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
      );
}
