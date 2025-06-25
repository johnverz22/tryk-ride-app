import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/bottom_nav_provider.dart';

class MainNavigation extends ConsumerWidget {

  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Define navigation items with their respective screens
    final List<BottomNavigationBarItem> navigationItems = [
      BottomNavigationBarItem(
        icon: Icon(Icons.map),
        label: 'Home',      // Real-time map + overlays
      activeIcon: Icon(Icons.map, size: 35,)
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.history),
        label: 'Trips',     // Trip history screen
      activeIcon: Icon(Icons.history, size: 35,)
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.attach_money),
        label: 'Earnings',  // Day/week/month earnings summary
      activeIcon: Icon(Icons.attach_money, size: 35,)
      ),
    ];

    // Get the current selected page from Riverpod
    final selectedIndex = ref.watch(bottomNavSelectionProvider);

    // Use the reusable NavigationContainer widget
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: (index) {
        ref.read(bottomNavSelectionProvider.notifier).state = index; // 👈 Update selected index
      },
      items: navigationItems,
      unselectedIconTheme: IconThemeData(
        color: Colors.grey[600], // Unselected icon color
      ),
      selectedIconTheme: IconThemeData(
        color: Theme.of(context).primaryColor, // Selected icon color
      ),
      showSelectedLabels: false,
      showUnselectedLabels: true,
      unselectedItemColor: Colors.black54,
    );
  }
}