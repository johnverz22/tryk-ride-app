import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/selected_page_provider.dart';

class MainNavigation extends ConsumerWidget {

  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Define navigation items with their respective screens
    final List<BottomNavigationBarItem> navigationItems = [
      BottomNavigationBarItem(
        icon: Icon(Icons.map),
        label: 'Home',      // Real-time map + overlays
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.history),
        label: 'Trips',     // Trip history screen
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.attach_money),
        label: 'Earnings',  // Day/week/month earnings summary
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_customize),
        label: 'Dashboard', // Profile, settings, documents
      ),
    ];

    // Get the current selected page from Riverpod
    final selectedIndex = ref.watch(selectedPageProvider);

    // Use the reusable NavigationContainer widget
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: (index) {
        ref.read(selectedPageProvider.notifier).state = index; // 👈 Update selected index
      },
      items: navigationItems,
      unselectedIconTheme: IconThemeData(
        color: Colors.grey[600], // Unselected icon color
      ),
      selectedIconTheme: IconThemeData(
        color: Theme.of(context).primaryColor, // Selected icon color
      ),
    );
  }
}