import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/skeleton/skeleton.dart';
// import 'features/skeleton/providers/selected_page_provider.dart';
import 'features/driver/presentation/pages/screens/auth/auth_screen.dart';
import 'features/driver/presentation/providers/driver_provider.dart';

void main() {
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const Home();
  }
}

class Home extends ConsumerWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverState = ref.watch(driverProvider);
    debugPaintSizeEnabled = false;
    // Show loading indicator while driver data is being loaded
    if (driverState.isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // final loggedIn = driverState.isAuthenticated;

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
      ),
      debugShowCheckedModeBanner: false,
      routes: {
        '/home': (context) => const Skeleton(),
        '/auth': (context) => const AuthScreen(),
        // Add other routes as needed
      },
      // home: loggedIn ? const Skeleton() : const AuthScreen(),
      home: const Skeleton(),
    );
  }
}
