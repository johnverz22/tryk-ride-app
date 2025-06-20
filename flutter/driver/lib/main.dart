import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/driver/presentation/pages/screens/main_navigation_screen.dart';
import 'features/driver/presentation/pages/screens/auth/auth_screen.dart';
import 'features/driver/presentation/providers/driver_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DriverProvider()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  Future<bool> checkLoggedIn(DriverProvider driverProvider) async {
    await driverProvider.loadDriverData();
    return driverProvider.token != null;
  }

  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);

    return FutureBuilder<bool>(
      future: checkLoggedIn(driverProvider),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final loggedIn = snapshot.data ?? false;

        return MaterialApp(
          title: 'Tryk',
          theme: ThemeData(
            primaryColor: Colors.pink,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
              iconTheme: IconThemeData(color: Colors.white),
            ),
            colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.pink).copyWith(
              secondary: Colors.pinkAccent,
            ),
            textTheme: const TextTheme(
              // bodyLarge: TextStyle(color: Colors.white),
              // bodyMedium: TextStyle(color: Colors.white),
              // titleLarge: TextStyle(color: Colors.white),
              // headlineSmall: TextStyle(color: Colors.white),
              // labelLarge: TextStyle(color: Colors.white),
            ),
          ),
          debugShowCheckedModeBanner: false,
          routes: {
            '/home': (context) => const MainNavigationScreen(),
            '/auth': (context) => const AuthScreen(),
            // Add other routes as needed
          },
          home: loggedIn ? const MainNavigationScreen() : const AuthScreen(),
        );
      },
    );
  }
}
