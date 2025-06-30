import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/skeleton/skeleton.dart';
import 'features/driver/presentation/pages/screens/auth/auth_screen.dart';
import 'features/driver/presentation/providers/driver_provider.dart';

void main() {
  debugPaintSizeEnabled = false;

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
    // Show loading indicator while driver data is being loaded
    if (driverState.isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AppRouter(isLoggedIn: driverState.isAuthenticated);
  }
}

class AppRouter extends StatelessWidget {
  const AppRouter({
    super.key,
    required this.isLoggedIn,
  });

  final bool isLoggedIn;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tryk',
      theme: ThemeData(
        primaryColor: Colors.pink,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.pink,
          foregroundColor: Color.fromARGB(255, 0, 0, 0),
          iconTheme: IconThemeData(color: Colors.black),
        ),
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.pink, backgroundColor: Color(0xFFFAF9F6)).copyWith(
          secondary: Colors.pinkAccent,
        ),
      ),
      debugShowCheckedModeBanner: false,
      routes: {
        '/home': (context) => const Skeleton(),
        '/auth': (context) => const AuthScreen(),
        // Add other routes as needed
      },
      home: isLoggedIn ? const Skeleton() : const AuthScreen(),
      // home: const Skeleton(),
    );
  }
}
