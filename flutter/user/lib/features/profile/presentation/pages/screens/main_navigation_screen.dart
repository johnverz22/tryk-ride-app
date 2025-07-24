import 'package:flutter/material.dart';
import 'package:user/features/profile/presentation/pages/screens/navigation/messages_screen.dart';
import 'navigation/home_screen.dart';
import '../../../../ride/presentation/screens/trips_screen.dart';
import 'navigation/menu_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    TripsScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      selectedIcon: Icon(Icons.home),
      icon: Icon(Icons.home_outlined),
      label: 'Home',
    ),
    NavigationDestination(
      selectedIcon: Icon(Icons.card_travel),
      icon: Icon(Icons.card_travel_outlined),
      label: 'Trips',
    ),
    NavigationDestination(
      selectedIcon: Icon(Icons.chat_bubble),
      icon: Icon(Icons.chat_bubble_outline),
      label: 'Messages',
    ),
    NavigationDestination(
      selectedIcon: Icon(Icons.menu),
      icon: Icon(Icons.menu_outlined),
      label: 'Menu',
    ),
  ];

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),

      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDarkMode ? Colors.grey[900]! : Colors.grey[200]!,
                width: 1.0,
              ),
            ),
          ),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              indicatorColor: theme.colorScheme.secondary.withValues(alpha: .1),
              indicatorShape: const StadiumBorder(),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              iconTheme: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return IconThemeData(color: theme.colorScheme.secondary);
                }
                return IconThemeData(color: Colors.grey[600]);
              }),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                final style = theme.textTheme.labelMedium;
                if (states.contains(WidgetState.selected)) {
                  return style?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                  );
                }
                return style?.copyWith(color: Colors.grey[500]);
              }),
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onTap,
              height: 65,
              elevation: 0,
              backgroundColor: isDarkMode
                  ? const Color(0xFF1A1A1A)
                  : Colors.white,
              destinations: _destinations,
            ),
          ),
        ),
      ),
    );
  }
}
