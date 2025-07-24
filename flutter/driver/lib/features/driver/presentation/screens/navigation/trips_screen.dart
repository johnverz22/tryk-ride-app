import 'package:driver/features/driver/presentation/providers/trip_list_provider.dart';
import 'package:driver/features/driver/presentation/screens/navigation/trips/ride_tracking_screen.dart';
import 'package:driver/features/driver/presentation/widgets/trips_screen/trip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Remove the intl import if it's no longer used directly in this file
// import 'package:intl/intl.dart';

import '../../widgets/widgets.dart';
// Remove this as it's handled inside the card
// import 'trips/ride_tracking_screen.dart';

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
    _tabController.addListener(() => setState(() {}));
    Future.microtask(() => _refreshTrips());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshTrips() async {
    await ref.read(driverTripListProvider.notifier).fetchTrips();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
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

  Widget _buildTripList(String category) {
    final tripListState = ref.watch(driverTripListProvider);

    return tripListState.when(
      loading: () => const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => Center(
        key: const ValueKey('error'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Failed to load trips: $error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (trips) {
        // --- Filtering logic remains unchanged ---
        final filteredTrips = trips.where((trip) {
          final tripStatus = trip['status']?['name'];
          final pickup = (trip['pickup_address'] ?? '').toLowerCase();
          final dropoff = (trip['dropoff_address'] ?? '').toLowerCase();
          final rider = (trip['user']?['name'] ?? '').toLowerCase();
          final query = _searchQuery.toLowerCase();

          bool categoryMatch = false;
          if (category == 'Ongoing') {
            categoryMatch = !['Completed', 'Cancelled'].contains(tripStatus);
          } else {
            categoryMatch = tripStatus == category;
          }
          if (!categoryMatch) return false;

          if (_searchQuery.isNotEmpty &&
              !(pickup.contains(query) ||
                  dropoff.contains(query) ||
                  rider.contains(query))) {
            return false;
          }

          if (_selectedDateRange != null) {
            final tripDate =
                DateTime.tryParse(trip['accepted_at'] ?? '') ?? DateTime.now();
            if (!(tripDate.isAfter(
                  _selectedDateRange!.start.subtract(
                    const Duration(seconds: 1),
                  ),
                ) &&
                tripDate.isBefore(
                  _selectedDateRange!.end.add(const Duration(days: 1)),
                ))) {
              return false;
            }
          }
          return true;
        }).toList();

        if (filteredTrips.isEmpty) {
          return _EmptyTripPlaceholder(
            key: ValueKey('empty_$category'),
            category: category,
          );
        }

        return RefreshIndicator(
          key: ValueKey('list_$category'),
          onRefresh: _refreshTrips,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: filteredTrips.length,
            itemBuilder: (context, index) {
              final trip = filteredTrips[index];
              return DriverTripCard(
                trip: trip,
                onViewDetails: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RideTrackingScreen(rideId: trip['id']),
                    ),
                  );
                },
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
      appBar: const CustomUserAppBar(),
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TripSearchBar(
                    onChanged: (value) => _onSearchChanged,
                    onFilterPressed: _showDateRangePicker,
                  ),
                ),
                if (_selectedDateRange != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear date filter',
                      onPressed: () =>
                          setState(() => _selectedDateRange = null),
                    ),
                  ),
              ],
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
              child: TabBarView(
                controller: _tabController,
                children: tripCategories
                    .map((cat) => _buildTripList(cat))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
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
