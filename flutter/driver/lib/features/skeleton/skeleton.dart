import 'package:driver/features/driver/presentation/pages/screens/navigation/trips_screen.dart';
import 'package:driver/features/driver/presentation/pages/screens/trip_screen_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/selected_page_provider.dart';
import '../driver/presentation/pages/screens/navigation/dashboard_screen.dart';
import '../driver/presentation/pages/screens/navigation/earnings_screen.dart';
import '../driver/presentation/pages/screens/navigation/home_screen.dart';
import '../skeleton/widgets/custom_app_bar.dart';
import 'widgets/main_navigation.dart';

class Skeleton extends ConsumerWidget {
  const Skeleton({super.key});

  // List of pages to be displayed in the skeleton
  static const List<Widget> pages = [
    HomeScreen(),
    TripsScreen(),
    // TripScreenUi(),
    EarningsScreen(),
    DashboardScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use Riverpod to watch the selected page
    final selectedIndex = ref.watch(selectedPageProvider);
    
    return Scaffold(
      appBar: CustomUserAppBar(),
      body: pages[selectedIndex],
      bottomNavigationBar: const MainNavigation(),
    );
  }
}