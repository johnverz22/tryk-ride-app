import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:user/features/ride/presentation/screens/ride_booking_screen.dart';

// import 'home/ride_booking_screen.dart'; // This line seems commented out, ensure correct path for widgets
import '../../../widgets/widgets.dart'; // Assuming this imports BannerCarousel, SectionTitle, SuggestionCard, PromotionCard
import '../../../providers/trip_provider.dart'; // Assuming Trip and its fetchOngoingTrips method are here
import '../../../../../../core/services/auth_service.dart'; // Assuming AuthService is here

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  final List<String> _bannerImages = [
    'assets/images/promotion_travel_fiesta.png',
    'assets/images/promotion_malaysia.png',
    'assets/images/promotion_inhouse_fair.png',
  ];
  final List<Map<String, String>> _promotions = [
    {
      'image': 'assets/images/ad_black_friday.png',
      'title': '20% Off On Black Friday!',
    },
    {
      'image': 'assets/images/ad_september_sale.png',
      'title': 'Refer & Earn Credits',
    },
    {
      'image': 'assets/images/ad_travel_sale.png',
      'title': 'Weekend Special Discounts',
    },
  ];
  final List<Map<String, dynamic>> _suggestions = [
    {'label': 'Airport Drop', 'icon': Icons.flight_takeoff},
    {'label': 'Daily Commute', 'icon': Icons.directions_bus},
    {'label': 'Visit a Cafe', 'icon': Icons.local_cafe},
  ];

  String? baseUrl = dotenv.env['BASE_URL'];
  Future<List<Trip>>? _futureTrips; // Assuming Trip model is still used here
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _loadTrips();
    _startAutoScroll();
  }

  void _loadTrips() async {
    final token = await AuthService().getToken();
    setState(() {
      _futureTrips = Trip.fetchOngoingTrips(token, baseUrl ?? '');
    });
  }

  void _startAutoScroll() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        final nextPage = _pageController.page!.round() + 1;
        _pageController.animateToPage(
          nextPage % _bannerImages.length,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshTrips() async {
    _loadTrips();
    await _futureTrips; // Wait for the future to complete
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomUserAppBar(),
      body: RefreshIndicator(
        onRefresh: _refreshTrips,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            const SizedBox(height: 12),
            BannerCarousel(controller: _pageController, images: _bannerImages),
            const SizedBox(height: 24),
            const SectionTitle('Suggestions for You'),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => SuggestionCard(
                  label: _suggestions[i]['label'],
                  icon: _suggestions[i]['icon'],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const SectionTitle('Recommended for You'),
            const SizedBox(height: 12),
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _promotions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (_, index) =>
                    PromotionCard(promo: _promotions[index]),
              ),
            ),
            const SizedBox(height: 24),
            // SectionHeaderWithSeeAll(title: 'Recent Trips', onSeeAll: () {}),
            // const SizedBox(height: 12),
            // RecentTripList(futureTrips: _futureTrips),
            // const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: () {
            // Using PageRouteBuilder for a custom transition
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const RideBookingScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      // Example: Fade transition
                      return FadeTransition(opacity: animation, child: child);
                      // Example: Slide transition from right
                      // const begin = Offset(1.0, 0.0);
                      // const end = Offset.zero;
                      // const curve = Curves.ease;
                      // var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                      // return SlideTransition(
                      //   position: animation.drive(tween),
                      //   child: child,
                      // );
                    },
                transitionDuration: const Duration(
                  milliseconds: 400,
                ), // Duration of the transition
              ),
            );
          },
          icon: const Icon(Icons.hail, color: Colors.white),
          label: const Text(
            'Book a Ride',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            shadowColor: theme.primaryColor.withOpacity(
              0.2,
            ), // Corrected alpha to opacity
          ),
        ),
      ),
    );
  }
}
