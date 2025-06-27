import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../widgets/widgets.dart';

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
  final List<String> tripCategories = ['Accepted', 'Completed', 'Cancelled'];

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
      setState(() {
        allTrips = trips;
        isLoading = false;
      });
    } else {
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

  Widget _buildTripList(String category) {
    List<Map<String, dynamic>> trips = allTrips
        .where((trip) => trip['status'] == category)
        .where(
          (trip) =>
              trip['pickup_address'].toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ||
              trip['dropoff_address'].toLowerCase().contains(
                searchQuery.toLowerCase(),
              ),
        )
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
            onViewDetails: () {},
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
            TripSearchBar(
              onChanged: (value) => setState(() => searchQuery = value),
              onFilterPressed: () {
                // TODO: Show filter modal
              },
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
