import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../widgets/custom_app_bar.dart';

List<Map<String, dynamic>> mockTrips = [
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
  }
];

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String searchQuery = '';
  bool isLoading = false;
  List<String> tripCategories = ['Upcoming', 'Completed', 'Canceled'];

  @override
  void initState() {
    _tabController = TabController(length: tripCategories.length, vsync: this);
    super.initState();
  }

  void _refreshTrips() async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => isLoading = false);
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search trips',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Open filter modal
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    return Dismissible(
      key: ValueKey(trip['id']),
      background: Container(
        color: Colors.blue.shade100,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.replay, color: Colors.blue),
      ),
      direction: DismissDirection.endToStart,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMM dd, yyyy – hh:mm a').format(trip['datetime']),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(trip['status']),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      trip['status'],
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Locations
              Row(
                children: [
                  const Icon(Icons.location_on, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(child: Text(trip['pickup'])),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.flag, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(child: Text(trip['dropoff'])),
                ],
              ),
              const SizedBox(height: 8),
              // Price & Payment
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Cost: \$${trip['price'].toStringAsFixed(2)}'),
                  Text('Paid via ${trip['payment']}'),
                ],
              ),
              const SizedBox(height: 8),
              // Driver
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Driver: ${trip['driver']} ★ ${trip['rating']}'),
                  if (trip['status'] == 'Completed')
                    TextButton(
                      onPressed: () {},
                      child: const Text('Rebook'),
                    ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // TODO: View Details
                  },
                  child: const Text('View Details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripList(String category) {
    List<Map<String, dynamic>> trips = mockTrips
        .where((trip) => trip['status'] == category)
        .where((trip) =>
            trip['pickup'].toLowerCase().contains(searchQuery.toLowerCase()) ||
            trip['dropoff'].toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    if (trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.airport_shuttle, size: 80, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No trips available'),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () {},
              child: const Text('Book a new ride'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _refreshTrips(),
      child: ListView.builder(
        itemCount: trips.length,
        itemBuilder: (context, index) => _buildTripCard(trips[index]),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Upcoming':
        return Colors.orange;
      case 'Completed':
        return Colors.green;
      case 'Canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
    backgroundColor: Colors.white,
    appBar: const CustomUserAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),

            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
              tabs: tripCategories
                  .map((category) => Tab(text: '$category Trips'))
                  .toList(),
            ),

            // Trip Lists
            Expanded(
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