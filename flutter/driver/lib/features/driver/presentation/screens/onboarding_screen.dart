import 'package:driver/features/driver/presentation/providers/shared_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Store page data in a model for cleaner code
  final List<_OnboardingItem> _pages = [
    _OnboardingItem(
      title: 'Need a Ride? Let’s Roll!',
      description:
          'With just a tap, nearby drivers are ready to pick you up — anytime, anywhere.',
      icon: Icons.directions_car_filled_outlined,
    ),
    _OnboardingItem(
      title: 'Track Every Turn, Live.',
      description:
          'Watch your ride move toward you in real-time. No more guessing, no more waiting.',
      icon: Icons.location_on_outlined,
    ),
    _OnboardingItem(
      title: 'Ready When You Are.',
      description: 'Book in seconds. Get there faster. Let’s move!',
      icon: Icons.emoji_transportation_outlined,
    ),
  ];

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  Future<void> _completeOnboarding() async {
    final sharedPrefs = ref.read(sharedPreferencesProvider);
    await sharedPrefs.setOnboarding();

    // Invalidate the provider to trigger a re-check in the router
    ref.invalidate(onboardingProvider);

    // The go_router redirection will handle the navigation automatically
    // after the provider state changes. If you need manual navigation:
    // if (mounted) context.go('/auth');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Softer background color
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _OnboardingPage(
                    item: _pages[index],
                    isActive:
                        index ==
                        _currentPage, // Pass active state for animations
                  );
                },
              ),
            ),
            Expanded(
              flex: 2,
              child: _BottomControls(
                pages: _pages,
                currentPage: _currentPage,
                pageController: _pageController,
                onDonePressed: _completeOnboarding,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// A dedicated widget for the bottom navigation controls
class _BottomControls extends StatelessWidget {
  final List<_OnboardingItem> pages;
  final int currentPage;
  final PageController pageController;
  final VoidCallback onDonePressed;

  const _BottomControls({
    required this.pages,
    required this.currentPage,
    required this.pageController,
    required this.onDonePressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastPage = currentPage == pages.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Modern page indicator
          SmoothPageIndicator(
            controller: pageController,
            count: pages.length,
            effect: WormEffect(
              dotHeight: 12,
              dotWidth: 12,
              activeDotColor: theme.colorScheme.primary,
              dotColor: theme.colorScheme.primary.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // UX IMPROVEMENT: Add a Skip button
              AnimatedOpacity(
                opacity: isLastPage ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: TextButton(
                  onPressed: onDonePressed,
                  child: const Text('Skip', style: TextStyle(fontSize: 16)),
                ),
              ),

              // Main action button with animated text
              ElevatedButton(
                onPressed: isLastPage
                    ? onDonePressed
                    : () {
                        pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                  backgroundColor: theme.colorScheme.primary,
                  shadowColor: theme.colorScheme.primary.withOpacity(0.4),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  ),
                  child: Text(
                    isLastPage ? 'Get Started' : 'Next',
                    key: ValueKey<bool>(isLastPage), // Key to trigger animation
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// The content of each onboarding page with entrance animations
class _OnboardingPage extends StatelessWidget {
  final _OnboardingItem item;
  final bool isActive;

  const _OnboardingPage({required this.item, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const duration = Duration(milliseconds: 500);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated icon container
        AnimatedContainer(
          duration: duration,
          curve: Curves.easeInOut,
          transform: Matrix4.translationValues(0, isActive ? 0 : 20, 0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                theme.colorScheme.primary.withOpacity(0.1),
                theme.colorScheme.primary.withOpacity(0.2),
              ],
            ),
          ),
          padding: const EdgeInsets.all(32),
          child: Icon(item.icon, size: 120, color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 60),
        // Animated text
        AnimatedOpacity(
          duration: duration,
          opacity: isActive ? 1.0 : 0.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  item.description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.black54,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Simple data class for onboarding content
class _OnboardingItem {
  final String title;
  final String description;
  final IconData icon;

  _OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
  });
}
