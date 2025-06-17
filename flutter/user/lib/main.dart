import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/user/presentation/pages/screens/main_navigation_screen.dart';
import 'features/user/presentation/pages/screens/auth/auth_screen.dart';
import 'features/user/presentation/providers/user_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  Future<bool> checkLoggedIn(UserProvider userProvider) async {
    await userProvider.loadToken();
    return userProvider.token != null;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return FutureBuilder<bool>(
      future: checkLoggedIn(userProvider),
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
          title: 'Flutter Navigation Demo',
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
          home: loggedIn ? const MainNavigationScreen() : const AuthScreen(),
        );
      },
    );
  }
}
