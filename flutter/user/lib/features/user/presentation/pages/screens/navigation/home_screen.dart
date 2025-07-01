import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'home/ride_booking_screen.dart';
import 'home/ride_tracking_screen.dart';
import '../../../widgets/widgets.dart';
import '../../../providers/trip_provider.dart';
import '../../../../../../core/services/auth_service.dart';

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
  String? baseUrl = dotenv.env['BASE_URL'];

  Future<List<Trip>>? _futureTrips;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  void _loadTrips() async {
    final token = await AuthService().getToken();
    setState(() {
      _futureTrips = Trip.fetchOngoingTrips(token, baseUrl ?? '');
    });
  }

  Future<void> _refreshTrips() async {
    try {
      _loadTrips();
      await _futureTrips;
    } catch (e) {
      print('Error refreshing trips: $e');
    }
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
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
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
            Text(
              'Suggestions for You',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
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
            SectionHeaderWithSeeAll(
              title: 'Ongoing Trips',
              onSeeAll: () {
                // Navigate to all trips screen if implemented
              },
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Trip>>(
              future: _futureTrips,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No ongoing trips at the moment.');
                }

                final trips = snapshot.data!;
                return SizedBox(
                  height: 320, // fixed height for scrolling list
                  child: ListView.separated(
                    itemCount: trips.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final trip = trips[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        shadowColor: Colors.grey.withOpacity(0.2),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          leading: Icon(
                            Icons.directions_car,
                            color: theme.primaryColor,
                            size: 28,
                          ),
                          title: Text(
                            trip.pickup_address,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  trip.dropoff_address,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '₱${trip.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 14,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    trip.rating > 0
                                        ? trip.rating.toStringAsFixed(1)
                                        : 'N/A',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RideTrackingScreen(
                                  rideId: int.tryParse(trip.id),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
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
