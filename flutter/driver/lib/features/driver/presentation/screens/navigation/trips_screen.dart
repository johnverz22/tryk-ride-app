import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../widgets/widgets.dart';
import '../../providers/driver_provider.dart';

import 'trips/ride_tracking_screen.dart';

class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  DateTimeRange? _selectedDateRange;

  final List<String> tripCategories = ['Ongoing', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tripCategories.length, vsync: this);
    _tabController.addListener(() => setState(() {})); // Rebuild on tab change
    Future.microtask(() => _refreshTrips());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshTrips() async {
    await ref.read(driverProvider.notifier).fetchTrips();
  }

  void _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget _buildTripList(String category) {
    final driverState = ref.watch(driverProvider);

    // Loading State
    if (driverState.isLoading && (driverState.value?.trips.isEmpty ?? true)) {
      return const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(),
      );
    }

    // Error State
    if (driverState.hasError && !driverState.hasValue) {
      return Center(
        key: const ValueKey('error'),
        child: Text(driverState.error.toString()),
      );
    }

    final trips = driverState.value?.trips ?? [];

    // Filtering Logic
    final filteredTrips = trips.where((trip) {
      final tripStatus = trip['status']?['name'];
      final pickup = (trip['pickup_address'] ?? '').toLowerCase();
      final dropoff = (trip['dropoff_address'] ?? '').toLowerCase();
      final rider = (trip['user']?['name'] ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();

      // Category Filter
      bool categoryMatch = false;
      if (category == 'Ongoing') {
        categoryMatch = !['Completed', 'Cancelled'].contains(tripStatus);
      } else {
        categoryMatch = tripStatus == category;
      }
      if (!categoryMatch) return false;

      // Search Filter
      if (_searchQuery.isNotEmpty &&
          !(pickup.contains(query) ||
              dropoff.contains(query) ||
              rider.contains(query))) {
        return false;
      }

      // Date Range Filter
      if (_selectedDateRange != null) {
        final tripDate =
            DateTime.tryParse(trip['accepted_at'] ?? '') ?? DateTime.now();
        if (!(tripDate.isAfter(
              _selectedDateRange!.start.subtract(const Duration(seconds: 1)),
            ) &&
            tripDate.isBefore(
              _selectedDateRange!.end.add(const Duration(days: 1)),
            ))) {
          return false;
        }
      }

      return true;
    }).toList();

    // Empty State
    if (filteredTrips.isEmpty) {
      return _EmptyTripPlaceholder(
        key: ValueKey('empty_$category'),
        category: category,
      );
    }

    // Content List
    return RefreshIndicator(
      key: ValueKey('list_$category'),
      onRefresh: _refreshTrips,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: filteredTrips.length,
        itemBuilder: (context, index) {
          return _buildTripCard(context, filteredTrips[index]);
        },
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, Map<String, dynamic> trip) {
    final pickupTime =
        DateTime.tryParse(trip['accepted_at'] ?? '') ?? DateTime.now();
    final date = DateFormat('EEE, MMM d, yyyy – h:mm a').format(pickupTime);
    final status = trip['status']?['name'] ?? 'Unknown';

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RideTrackingScreen(rideId: trip['id']),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.1),
                    child: Text(
                      (trip['user']?['name'] ?? 'U').substring(0, 1),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip['user']?['name'] ?? 'Unknown Rider',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(status),
                    labelStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    backgroundColor: _getStatusColor(status),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _InfoRow(
                icon: Icons.location_on,
                iconColor: Colors.blue,
                text: trip['pickup_address'] ?? 'Unknown Pickup',
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.flag,
                iconColor: Colors.green,
                text: trip['dropoff_address'] ?? 'Unknown Destination',
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Align items vertically
                children: [
                  // THE FIX IS HERE: Wrap the _InfoRow in an Expanded widget.
                  Expanded(
                    child: _InfoRow(
                      icon: Icons.payment,
                      iconColor: Colors.grey.shade700,
                      text: trip['payment_method'] ?? 'N/A',
                    ),
                  ),
                  const SizedBox(width: 8), // Add some spacing
                  Text(
                    '₱${(trip['fare_amount'] ?? 0).toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomUserAppBar(),
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TripSearchBar(
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      onFilterPressed: _showDateRangePicker,
                    ),
                  ),
                  if (_selectedDateRange != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Clear date filter',
                        onPressed: () =>
                            setState(() => _selectedDateRange = null),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  labelColor: Colors.white,
                  unselectedLabelColor: theme.colorScheme.primary,
                  labelStyle: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  tabs: tripCategories
                      .map(
                        (category) => Tab(child: Center(child: Text(category))),
                      )
                      .toList(),
                ),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildTripList(tripCategories[_tabController.index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
      ],
    );
  }
}

class _EmptyTripPlaceholder extends StatelessWidget {
  final String category;
  const _EmptyTripPlaceholder({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            'No $category Trips',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'You have no ${category.toLowerCase()} trips at the moment.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
