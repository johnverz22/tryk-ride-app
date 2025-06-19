import 'package:flutter/material.dart';
import '../../../widgets/widgets.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String searchQuery = '';
  bool isLoading = false;

  final List<String> tripCategories = ['Upcoming', 'Completed', 'Canceled'];

  final List<Map<String, dynamic>> mockTrips = [
    {
      'id': '1',
      'datetime': DateTime.now().subtract(const Duration(days: 1)),
      'pickup': 'Airport Terminal 1',
      'dropoff': 'Downtown Hotel',
      'price': 23.5,
      'payment': 'Credit Card',
      'driver': 'John Smith',
      'rating': 4.5,
      'status': 'Completed'
    },
    {
      'id': '2',
      'datetime': DateTime.now().add(const Duration(hours: 5)),
      'pickup': 'City Center',
      'dropoff': 'Museum District',
      'price': 12.0,
      'payment': 'Wallet',
      'driver': 'Alice Brown',
      'rating': 4.8,
      'status': 'Upcoming'
    },
    {
      'id': '3',
      'datetime': DateTime.now().subtract(const Duration(days: 3)),
      'pickup': 'Stadium',
      'dropoff': 'Suburb 5',
      'price': 15.0,
      'payment': 'Cash',
      'driver': 'Mark Lee',
      'rating': 4.1,
      'status': 'Canceled'
    },
  ];

  @override
  void initState() {
    _tabController = TabController(length: tripCategories.length, vsync: this);
    super.initState();
  }

  Future<void> _refreshTrips() async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => isLoading = false);
  }

  Widget _buildTripList(String category) {
    List<Map<String, dynamic>> trips = mockTrips
        .where((trip) => trip['status'] == category)
        .where((trip) =>
            trip['pickup'].toLowerCase().contains(searchQuery.toLowerCase()) ||
            trip['dropoff'].toLowerCase().contains(searchQuery.toLowerCase()))
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
        physics: const BouncingScrollPhysics(),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          return TripCard(
            trip: trips[index],
            onViewDetails: () {
              // TODO: Navigate to trip details
            },
            onRebook: () {
              // TODO: Implement rebook functionality
            },
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
              labelStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              indicatorColor: theme.primaryColor,
              tabs: tripCategories.map((category) => Tab(text: category)).toList(),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: tripCategories.map((category) => _buildTripList(category)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
