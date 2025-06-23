import 'package:driver/features/trips/business/entities/trip_entity.dart';
import 'package:driver/features/trips/data/models/mock_trip_datasource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Search query
final searchQueryProvider = StateProvider<String>((ref) => '');

// Loading state
final isLoadingProvider = StateProvider<bool>((ref) => false);

// Filtered trips by category
final filteredTripsProvider = Provider.family<List<TripEntity>, String>((ref, category) {
  final trips = ref.watch(mockTripsProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  return trips.where((trip) {
    final matchesCategory = trip.status == category;
    final matchesQuery = trip.pickup.toLowerCase().contains(query) ||
        trip.dropoff.toLowerCase().contains(query) ||
        trip.rider.toLowerCase().contains(query);
    return matchesCategory && matchesQuery;
  }).toList();
});
