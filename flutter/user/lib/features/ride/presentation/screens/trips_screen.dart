// user/features/ride/presentation/screens/trips_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user/features/profile/presentation/widgets/appbar/app_bar.dart';
import 'package:user/features/ride/presentation/screens/ride_tracking_screen.dart';

import '../providers/trip_list_provider.dart';
import '../../domain/entities/trip_entity.dart';
import '../widgets/trips_screen/widgets.dart';

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
    // Add a listener to rebuild the widget when the tab changes
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    // Only rebuild if the tab selection has settled (not during animation)
    if (!_tabController.indexIsChanging) {
      setState(() {
        // This setState will trigger _buildTripList to rebuild with the new category
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection); // Remove the listener
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshTrips() async {
    await ref.read(tripListProvider.notifier).loadTrips(isRefresh: true);
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
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  Widget _buildTripList(String category) {
    final tripListState = ref.watch(tripListProvider);
    final List<TripEntity> allTrips = tripListState.trips.value ?? [];

    List<TripEntity> filteredTrips = allTrips
        .where((trip) {
          // Filter by category
          if (category == 'Ongoing') {
            return trip.isOngoing;
          } else if (category == 'Completed') {
            return trip.isCompleted;
          } else if (category == 'Cancelled') {
            return trip.isCancelled;
          }
          return false; // Should not happen
        })
        .where((trip) {
          // Filter by search query
          final matchesSearch =
              trip.pickupAddress.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              trip.dropoffAddress.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );
          return matchesSearch;
        })
        .where((trip) {
          // Filter by date range
          if (_selectedDateRange != null) {
            final tripDate = trip.requestedAt;
            return tripDate.isAfter(
                  _selectedDateRange!.start.subtract(
                    const Duration(seconds: 1),
                  ),
                ) &&
                tripDate.isBefore(
                  _selectedDateRange!.end.add(const Duration(days: 1)),
                );
          }
          return true; // No date filter applied
        })
        .toList();

    // Sort the filtered trips by requestedAt in descending order
    filteredTrips.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));

    if (tripListState.trips.isLoading && allTrips.isEmpty) {
      return const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(),
      );
    }

    if (tripListState.trips.hasError && allTrips.isEmpty) {
      return Center(
        key: const ValueKey('error'),
        child: Text(tripListState.errorMessage ?? 'Failed to load trips.'),
      );
    }

    if (filteredTrips.isEmpty) {
      return EmptyTripPlaceholder(
        key: ValueKey(
          'empty_$category',
        ), // Unique key for each category's placeholder
        category: category,
        onBookPressed: () {
          // TODO: Navigate to ride booking
        },
      );
    }

    return RefreshIndicator(
      key: ValueKey('list_$category'), // Unique key for each category's list
      onRefresh: _refreshTrips,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount:
            filteredTrips.length +
            (tripListState.hasMore ? 1 : 0), // Add 1 for loading indicator
        itemBuilder: (context, index) {
          if (index == filteredTrips.length) {
            if (tripListState.hasMore && !tripListState.trips.isLoading) {
              // *** FIX: Wrap the call in a Future.microtask ***
              Future.microtask(() {
                ref.read(tripListProvider.notifier).loadTrips(loadMore: true);
              });
              return const Center(child: CircularProgressIndicator());
            }
            return const SizedBox.shrink();
          }

          final trip = filteredTrips[index];
          return TripCard(
            trip: trip,
            onViewDetails: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RideTrackingScreen(
                    rideId: trip.id, // Use TripEntity's ID
                  ),
                ),
              );
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
                    onChanged: _onSearchChanged,
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
