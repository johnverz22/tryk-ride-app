import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../widgets/widgets.dart'; // Assumes CustomUserAppBar & TripSearchBar are here

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
      'rider': 'Anna Carter',
      'rating': 4.5,
      'status': 'Completed',
    },
    {
      'id': '2',
      'datetime': DateTime.now().add(const Duration(hours: 5)),
      'pickup': 'City Center',
      'dropoff': 'Museum District',
      'price': 12.0,
      'payment': 'Wallet',
      'rider': 'Ben Morris',
      'rating': null,
      'status': 'Upcoming',
    },
    {
      'id': '3',
      'datetime': DateTime.now().subtract(const Duration(days: 3)),
      'pickup': 'Stadium',
      'dropoff': 'Suburb 5',
      'price': 15.0,
      'payment': 'Cash',
      'rider': 'Sarah Lee',
      'rating': 4.1,
      'status': 'Canceled',
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
    final filteredTrips = mockTrips
        .where((trip) => trip['status'] == category)
        .where((trip) {
          final pickup = trip['pickup'].toLowerCase();
          final dropoff = trip['dropoff'].toLowerCase();
          final rider = trip['rider']?.toLowerCase() ?? '';
          final query = searchQuery.toLowerCase();

          return pickup.contains(query) ||
              dropoff.contains(query) ||
              rider.contains(query);
        })
        .toList();

    if (filteredTrips.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_car, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 20),
              Text(
                'No $category trips found',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshTrips,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: filteredTrips.length,
        itemBuilder: (context, index) {
          final trip = filteredTrips[index];
          final date = DateFormat('EEE, MMM d – h:mm a').format(trip['datetime']);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.grey, size: 18),
                      const SizedBox(width: 6),
                      Text(trip['rider'], style: const TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Chip(
                        label: Text(
                          trip['status'],
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        backgroundColor: trip['status'] == 'Completed'
                            ? Colors.green.shade100
                            : trip['status'] == 'Canceled'
                                ? Colors.red.shade100
                                : Colors.orange.shade100,
                        labelStyle: TextStyle(
                          color: trip['status'] == 'Completed'
                              ? Colors.green.shade800
                              : trip['status'] == 'Canceled'
                                  ? Colors.red.shade800
                                  : Colors.orange.shade800,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_pin, color: Colors.purple),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${trip['pickup']} → ${trip['dropoff']}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(date, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.payment, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(trip['payment'], style: const TextStyle(fontSize: 13)),
                      const Spacer(),
                      Text(
                        '\$${trip['price'].toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  if (trip['rating'] != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text('${trip['rating']}', style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: const CustomUserAppBar(title: "Your Trips"),
      body: Column(
        children: [
          TripSearchBar(
            onChanged: (value) => setState(() => searchQuery = value),
            onFilterPressed: () {
              // TODO: Add filter modal or sort feature
            },
          ),
          TabBar(
            controller: _tabController,
            labelColor: theme.primaryColor,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            indicatorColor: theme.primaryColor,
            tabs: tripCategories.map((category) => Tab(text: category)).toList(),
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: tripCategories.map(_buildTripList).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
