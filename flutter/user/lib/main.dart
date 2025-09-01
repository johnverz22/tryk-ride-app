import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/di/injection_container.dart' as di;
import 'core/config/app_config.dart';
import 'features/user/presentation/pages/screens/main_navigation_screen.dart';
import 'features/user/presentation/pages/screens/auth/auth_screen.dart';
import 'features/user/presentation/viewmodels/user_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🚀 PLUG AND PLAY: Configuration-driven initialization
  await di.init(
    enableLoadBalancer: AppConfig.enableLoadBalancer,
    enableMessageQueue: AppConfig.enableMessageQueue,
    loadBalancerStrategy: AppConfig.loadBalancerStrategy,
    messageQueueType: AppConfig.messageQueueType,
  );
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => di.sl<UserViewModel>(),
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserViewModel>(
      builder: (context, userViewModel, _) {
        return FutureBuilder(
          future: userViewModel.loadUser(),
          builder: (context, snapshot) {
            if (userViewModel.isLoading) {
              return const MaterialApp(
                home: Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
              );
            }

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
          home: userViewModel.isAuthenticated ? const MainNavigationScreen() : const AuthScreen(),
        );
      },
    );
        );
      },
    );
  }
}
