import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/navigation/home_screen.dart';
import '../screens/navigation/trips_screen.dart';
import '../screens/navigation/earnings_screen.dart';
import '../screens/navigation/dashboard_screen.dart';
import '../screens/navigation/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  final List<Widget> _pages = const [
    HomeScreen(),
    TripsScreen(),
    EarningsScreen(),
    DashboardScreen(),
    ProfileScreen(),
  ];

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Trips'),
    BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Earnings'),
    BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_customize),
      label: 'Dashboard',
    ),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTap(int index) {
    final routeNames = ['home', 'trips', 'earnings', 'dashboard', 'profile'];
    context.goNamed(routeNames[index]);
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
