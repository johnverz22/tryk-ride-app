import 'package:flutter/material.dart';
import '../screens/navigation/home_screen.dart';
import '../screens/navigation/trips_screen.dart';
import '../screens/navigation/earnings_screen.dart';
import '../screens/navigation/dashboard_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),       // Real-time map + overlays
    TripsScreen(),      // Trip history screen
    EarningsScreen(),   // Day/week/month earnings summary
    DashboardScreen(),  // Profile, settings, documents
  ];

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.map),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.history),
      label: 'Trips',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.attach_money),
      label: 'Earnings',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_customize),
      label: 'Dashboard',
    ),
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
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        items: _navItems,
      ),
    );
  }
}
