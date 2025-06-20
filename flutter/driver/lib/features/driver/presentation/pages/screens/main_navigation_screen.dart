import 'package:flutter/material.dart';
import '../screens/navigation/home_screen.dart';
import '../screens/navigation/trips_screen.dart';
import '../screens/navigation/earnings_screen.dart';
import '../screens/navigation/dashboard_screen.dart';
import '../../widgets/custom_bottom_navigation.dart';

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Define navigation items with their respective screens
    final List<NavigationItemData> navigationItems = [
      const NavigationItemData(
        icon: Icons.map,
        label: 'Home',
        screen: HomeScreen(),       // Real-time map + overlays
      ),
      const NavigationItemData(
        icon: Icons.history,
        label: 'Trips',
        screen: TripsScreen(),      // Trip history screen
      ),
      const NavigationItemData(
        icon: Icons.attach_money,
        label: 'Earnings',
        screen: EarningsScreen(),   // Day/week/month earnings summary
      ),
      const NavigationItemData(
        icon: Icons.dashboard_customize,
        label: 'Dashboard',
        screen: DashboardScreen(),  // Profile, settings, documents
      ),
    ];

    // Use the reusable NavigationContainer widget
    return NavigationContainer(
      items: navigationItems,
      initialIndex: 0,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey[600],
      type: BottomNavigationBarType.fixed,
    );
  }
}
