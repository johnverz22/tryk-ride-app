import '../providers/app_bar_provider.dart';
import '../../../earnings/presentation/screens/earnings_overlay.dart';
import '../widgets/profile_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_screen.dart';
import '../widgets/app_bar.dart';
import '../widgets/bottom_nav.dart';

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
                ref.read(overlayEarnings.notifier).state =
                    false; // Hide overlay on tap
              },
              child: Container(
                color: const Color.fromARGB(
                  20,
                  0,
                  0,
                  0,
                ), // Darken the background
                child: OverlayEntryWidget(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const MainNavigation(),
    );
  }
}
