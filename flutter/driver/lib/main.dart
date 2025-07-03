import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/driver/presentation/pages/screens/main_navigation_screen.dart';
import 'features/driver/presentation/pages/screens/auth/auth_screen.dart';
import 'features/driver/presentation/providers/driver_provider.dart';

// FutureProvider to check if logged in by loading driver data
final isLoggedInProvider = FutureProvider<bool>((ref) async {
  final driver = ref.read(driverProvider);
  await driver.loadDriverData();
  return driver.token != null;
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncLoggedIn = ref.watch(isLoggedInProvider);

    return asyncLoggedIn.when(
      loading: () => const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (error, stack) => MaterialApp(
        home: Scaffold(body: Center(child: Text('Error: $error'))),
      ),
      data: (loggedIn) => MaterialApp(
        title: 'Tryk',
        theme: ThemeData(
          primaryColor: Colors.pink,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.pink,
            foregroundColor: Colors.white,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.pink,
          ).copyWith(secondary: Colors.pinkAccent),
        ),
        debugShowCheckedModeBanner: false,
        routes: {
          '/home': (context) => const MainNavigationScreen(),
          '/auth': (context) => const AuthScreen(),
        },
        home: loggedIn ? const MainNavigationScreen() : const AuthScreen(),
      ),
    );
  }
}
