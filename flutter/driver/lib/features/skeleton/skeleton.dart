import 'package:driver/features/skeleton/providers/app_bar_provider.dart';
import 'package:driver/features/skeleton/widgets/overlay_earnings_widget.dart';
import 'package:driver/features/skeleton/widgets/profile_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../driver/presentation/pages/screens/navigation/home_screen.dart';
import '../skeleton/widgets/custom_app_bar.dart';
import 'widgets/main_navigation.dart';

class Skeleton extends ConsumerWidget {
  const Skeleton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOverlayEarningsVisible = ref.watch(overlayEarnings);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomUserAppBar(),
      drawer: const ProfileDrawer(),
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