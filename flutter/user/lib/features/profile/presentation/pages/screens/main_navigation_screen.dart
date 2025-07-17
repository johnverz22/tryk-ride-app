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
    // MessagesScreen(),
    // SavedPlacesScreen(),
    MessagesScreen(),
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
      body: _pages[_currentIndex],
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
            icon: Icon(_currentIndex == 2 ? Icons.chat : Icons.chat_outlined),
            label: 'Messages',
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
