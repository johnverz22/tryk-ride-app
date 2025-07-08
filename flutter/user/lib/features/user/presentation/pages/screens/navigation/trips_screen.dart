import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../widgets/widgets.dart';
import '../../screens/navigation/home/ride_tracking_screen.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String searchQuery = '';
  bool isLoading = false;
  List<Map<String, dynamic>> allTrips = [];
  String? baseUrl = dotenv.env['BASE_URL'];

  final storage = FlutterSecureStorage();
  final List<String> tripCategories = ['Ongoing', 'Completed', 'Cancelled'];
  DateTimeRange? selectedDateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tripCategories.length, vsync: this);
    _loadTrips();
  }

  Future<String?> _getUserToken() async {
    return await storage.read(key: 'token');
  }

  Future<void> _loadTrips() async {
    setState(() => isLoading = true);
    final token = await _getUserToken();
    if (token != null) {
      final trips = await fetchUserTrips(token);

      // Log the fetched trips
      debugPrint("Fetched user trips: $trips");

      setState(() {
        allTrips = trips;
        isLoading = false;
      });
    } else {
      debugPrint("User token not found. Unable to load trips.");
      setState(() => isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> fetchUserTrips(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/trips'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('Failed to fetch trips: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching trips: $e');
      return [];
    }
  }

  Future<void> _refreshTrips() async {
    await _loadTrips();
  }

  void _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
      initialDateRange: selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
      });
    }
  }

  Widget _buildTripList(String category) {
    List<Map<String, dynamic>> trips = allTrips
        .where((trip) {
          final status = trip['status'];
          if (category == 'Ongoing') {
            return [
              'Accepted',
              'Driver En Route',
              'Ride Started Awaiting User Confirmation',
              'Ride in Progress',
              'Ride Completed Awaiting User Confirmation',
            ].contains(status);
          }
          return status == category;
        })
        .where((trip) {
          final pickup = trip['pickup_address'].toLowerCase();
          final dropoff = trip['dropoff_address'].toLowerCase();
          final matchesSearch =
              pickup.contains(searchQuery.toLowerCase()) ||
              dropoff.contains(searchQuery.toLowerCase());

          if (selectedDateRange != null) {
            final tripDate = DateTime.tryParse(trip['requested_at'] ?? '');
            if (tripDate == null) return false;

            return matchesSearch &&
                tripDate.isAfter(
                  selectedDateRange!.start.subtract(const Duration(seconds: 1)),
                ) &&
                tripDate.isBefore(
                  selectedDateRange!.end.add(const Duration(days: 1)),
                );
          }

          return matchesSearch;
        })
        .toList();

    if (trips.isEmpty) {
      return EmptyTripPlaceholder(
        category: category,
        onBookPressed: () {
          // TODO: Navigate to ride booking
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshTrips,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          return TripCard(
            trip: trips[index],
            onViewDetails: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RideTrackingScreen(
                    rideId: int.tryParse(trips[index]['id'].toString()),
                  ),
                ),
              );
            },
            onRebook: () {},
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomUserAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TripSearchBar(
                    onChanged: (value) => setState(() => searchQuery = value),
                    onFilterPressed: _showDateRangePicker,
                  ),
                ),
                if (selectedDateRange != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear date filter',
                    onPressed: () {
                      setState(() {
                        selectedDateRange = null;
                      });
                    },
                  ),
              ],
            ),
            TabBar(
              controller: _tabController,
              labelColor: theme.primaryColor,
              unselectedLabelColor: Colors.grey,
              labelStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              indicatorColor: theme.primaryColor,
              tabs: tripCategories
                  .map((category) => Tab(text: category))
                  .toList(),
            ),
            isLoading
                ? const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: tripCategories
                          .map((category) => _buildTripList(category))
                          .toList(),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
