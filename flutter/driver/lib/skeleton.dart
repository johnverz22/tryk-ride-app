import 'package:driver/presentation/providers/skeleton_app_bar_provider.dart';
import 'package:driver/presentation/widgets/home_overlay_earnings_widget.dart';
import 'package:driver/presentation/widgets/skeleton_profile_drawer_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/widgets/skeleton_app_bar_widget.dart';
import 'presentation/widgets/skeleton_bottom_nav_widget.dart';

class Skeleton extends ConsumerWidget {
  const Skeleton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOverlayEarningsVisible = ref.watch(overlayEarnings);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomUserAppBar(),
      drawer: ProfileDrawer(),
      body: Stack(
        children: [
          // Display the selected page
          HomeScreen(),
          // Overlay widget for earnings
          if (isOverlayEarningsVisible) 
            GestureDetector(
              onTap: () {
                ref.read(overlayEarnings.notifier).state = false; // Hide overlay on tap
              },
              child: Container(
                color: const Color.fromARGB(20, 0, 0, 0), // Darken the background
                child: OverlayEntryWidget(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const MainNavigation(),
    );
  }
}