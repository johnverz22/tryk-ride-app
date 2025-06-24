import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../ride_booking_screen.dart';
import '../../../widgets/widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  final List<String> _bannerImages = [
    'assets/images/ads.png',
    'assets/images/ads.png',
    'assets/images/ads.png',
  ];

  final List<Map<String, dynamic>> _recentTrips = [
    {'title': 'Golden Gate Park', 'subtitle': '501 Stanyan St, San Francisco'},
    {'title': 'Union Square', 'subtitle': '333 Post St, San Francisco'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomUserAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Swipable Banner Carousel
          SizedBox(
            height: 180,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _bannerImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: AssetImage(_bannerImages[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: SmoothPageIndicator(
              controller: _pageController,
              count: _bannerImages.length,
              effect: ExpandingDotsEffect(
                dotHeight: 8,
                dotWidth: 8,
                activeDotColor: theme.primaryColor,
                dotColor: Colors.grey.shade300,
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Suggestions
          Text(
            'Suggestions for You',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _suggestionCard('Airport Drop', Icons.flight_takeoff),
                _suggestionCard('Daily Commute', Icons.directions_bus),
                _suggestionCard('Visit a Cafe', Icons.local_cafe),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Recent Trips
          Text(
            'Recent Trips',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ..._recentTrips.map(
            (trip) => RecentTripTile(
              title: trip['title']!,
              subtitle: trip['subtitle']!,
              onTap: () {
                // You can prefill destination later using context or arguments
              },
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RideBookingScreen()),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
          ),
          child: const Text(
            'Book a Ride',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _suggestionCard(String label, IconData icon) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: Colors.blue),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
