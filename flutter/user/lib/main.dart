import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/user/presentation/pages/screens/main_navigation_screen.dart';
import 'features/user/presentation/pages/screens/auth/auth_screen.dart';
import 'features/user/presentation/providers/user_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      loading: () => const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (err, stack) => MaterialApp(
        home: Scaffold(body: Center(child: Text('Error: $err'))),
      ),
      data: (userState) => MaterialApp(
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
        home: userState.isAuthenticated
            ? const MainNavigationScreen()
            : const AuthScreen(),
      ),
    );
  }
}
