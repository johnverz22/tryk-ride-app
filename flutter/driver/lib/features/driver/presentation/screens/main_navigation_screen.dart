import 'package:driver/features/driver/presentation/screens/navigation/dashboard_screen.dart';
import 'package:driver/features/driver/presentation/screens/navigation/earnings_screen.dart';
import 'package:driver/features/driver/presentation/screens/navigation/profile_screen.dart';
import 'package:driver/features/driver/presentation/screens/navigation/trips_screen.dart';
import 'package:flutter/material.dart';
import 'navigation/home_screen.dart';

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
    EarningsScreen(),
    ProfileScreen(),
  ];

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(
          milliseconds: 300,
        ), // Adjust duration as needed
        // Use a ValueKey to tell AnimatedSwitcher when the child changes
        child: SizedBox.expand(
          // Use SizedBox.expand to ensure the child fills the available space
          key: ValueKey<int>(_currentIndex), // Key changes with the index
          child: _pages[_currentIndex],
        ),
        // Optional: Customize the transition. Default is a fade.
        // transitionBuilder: (Widget child, Animation<double> animation) {
        //   return FadeTransition(opacity: animation, child: child);
        // },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(_currentIndex == 0 ? Icons.home : Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _currentIndex == 1
                  ? Icons.card_travel
                  : Icons.card_travel_outlined,
            ),
            label: 'Trips',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _currentIndex == 2
                  ? Icons.monetization_on
                  : Icons.monetization_on_outlined,
            ),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: Icon(_currentIndex == 3 ? Icons.menu : Icons.menu_outlined),
            label: 'Menu',
          ),
        ],
      ),
    );
  }
}
