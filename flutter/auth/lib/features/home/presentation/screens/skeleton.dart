import '../../../earnings/presentation/screens/earnings_overlay.dart';
import '../widgets/profile_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_screen.dart';
import '../widgets/app_bar.dart';
import '../widgets/bottom_nav.dart';

class Skeleton extends ConsumerStatefulWidget {
  const Skeleton({super.key});

  @override
  ConsumerState<Skeleton> createState() => _Skeleton();
}

class _Skeleton extends ConsumerState<Skeleton> {
  bool overlayVisibile = false;

  void _toggleOverlay() {
    setState(() {
      overlayVisibile = !overlayVisibile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomUserAppBar(toggleOverlay: _toggleOverlay),
      drawer: ProfileDrawer(),
      body: Stack(
        children: [
          // Display the selected page
          HomeScreen(),
          // Overlay widget for earnings
          if (overlayVisibile)
            GestureDetector(
              onTap: () {
                _toggleOverlay; // Hide overlay on tap
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
