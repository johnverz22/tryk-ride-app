import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../widgets/widgets.dart';
import '../../../providers/driver_provider.dart';

import 'trips/ride_tracking_screen.dart';

class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String searchQuery = '';
  bool isLoading = false;
  DateTimeRange? selectedDateRange;

  final List<String> tripCategories = ['Ongoing', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tripCategories.length, vsync: this);
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() => isLoading = true);

    final driverNotifier = ref.read(driverProvider.notifier);
    await driverNotifier.fetchTrips();

    setState(() => isLoading = false);
  }

  void _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
      initialDateRange: selectedDateRange,
    );

    if (picked != null) {
      setState(() => selectedDateRange = picked);
    }
  }

  Color _getStatusColor(String status, {bool background = false}) {
    switch (status) {
      case 'Completed':
        return background ? Colors.green.shade100 : Colors.green.shade800;
      case 'Cancelled':
        return background ? Colors.red.shade100 : Colors.red.shade800;
      default:
        return background ? Colors.orange.shade100 : Colors.orange.shade800;
    }
  }

  Widget _buildTripList(BuildContext context, WidgetRef ref, String category) {
    final asyncDriver = ref.watch(driverProvider);

    return asyncDriver.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (driverState) {
        final trips = driverState!.trips;

        final filteredTrips = trips
            .where((trip) {
              final tripStatus = trip['status']?['name'];

              if (category == 'Ongoing') {
                return [
                  'Accepted',
                  'Driver En Route',
                  'Ride Started Awaiting User Confirmation',
                  'Ride in Progress',
                  'Ride Completed Awaiting User Confirmation',
                ].contains(tripStatus);
              }

              return tripStatus == category;
            })
            .where((trip) {
              final pickup = (trip['pickup_address'] ?? '').toLowerCase();
              final dropoff = (trip['dropoff_address'] ?? '').toLowerCase();
              final rider = (trip['user']?['name'] ?? '').toLowerCase();
              final query = searchQuery.toLowerCase();

              final matchesSearch =
                  pickup.contains(query) ||
                  dropoff.contains(query) ||
                  rider.contains(query);

              if (selectedDateRange != null) {
                final tripDate =
                    DateTime.tryParse(trip['accepted_at'] ?? '') ??
                    DateTime.now();
                return matchesSearch &&
                    tripDate.isAfter(
                      selectedDateRange!.start.subtract(
                        const Duration(seconds: 1),
                      ),
                    ) &&
                    tripDate.isBefore(
                      selectedDateRange!.end.add(const Duration(days: 1)),
                    );
              }

              return matchesSearch;
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
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadTrips,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: filteredTrips.length,
            itemBuilder: (context, index) {
              final trip = filteredTrips[index];
              final pickupTime =
                  DateTime.tryParse(trip['accepted_at'] ?? '') ??
                  DateTime.now();
              final date = DateFormat('EEE, MMM d – h:mm a').format(pickupTime);
              final status = trip['status']['name'];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RideTrackingScreen(rideId: trip['id']),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              color: Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              trip['user']?['name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Chip(
                              label: Text(
                                status,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              backgroundColor: _getStatusColor(
                                status,
                                background: true,
                              ),
                              labelStyle: TextStyle(
                                color: _getStatusColor(status),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_pin,
                              color: Colors.purple,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${trip['pickup_address'] ?? 'Unknown'} → ${trip['dropoff_address'] ?? 'Unknown'}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              date,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.payment,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              trip['payment_method'] ?? 'Unknown',
                              style: const TextStyle(fontSize: 13),
                            ),
                            const Spacer(),
                            Text(
                              '₱${(trip['fare_amount'] ?? 0).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomUserAppBar(),
      backgroundColor: Colors.grey[100],
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
                    onPressed: () => setState(() => selectedDateRange = null),
                  ),
              ],
            ),
            TabBar(
              controller: _tabController,
              labelColor: theme.primaryColor,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              indicatorColor: theme.primaryColor,
              tabs: tripCategories
                  .map((category) => Tab(text: category))
                  .toList(),
            ),
            const Divider(height: 1),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: tripCategories
                          .map(
                            (category) =>
                                _buildTripList(context, ref, 'Completed'),
                          )
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
