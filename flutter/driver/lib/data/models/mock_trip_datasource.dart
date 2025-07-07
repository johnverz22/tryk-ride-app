import 'package:driver/domain/entities/trip_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mockTripsProvider = Provider<List<TripEntity>>((ref) => [
  TripEntity(
    id: '1',
    datetime: DateTime.now().subtract(const Duration(days: 1)),
    pickup: 'Airport Terminal 1',
    dropoff: 'Downtown Hotel',
    price: 23.5,
    payment: 'Credit Card',
    rider: 'Anna Carter',
    rating: 4.5,
    status: 'Completed',
  ),
  TripEntity(
    id: '2',
    datetime: DateTime.now().add(const Duration(hours: 5)),
    pickup: 'City Center',
    dropoff: 'Museum District',
    price: 12.0,
    payment: 'Wallet',
    rider: 'Ben Morris',
    rating: null,
    status: 'Upcoming',
  ),
  TripEntity(
    id: '3',
    datetime: DateTime.now().subtract(const Duration(days: 3)),
    pickup: 'Stadium',
    dropoff: 'Suburb 5',
    price: 15.0,
    payment: 'Cash',
    rider: 'Sarah Lee',
    rating: 4.1,
    status: 'Canceled',
  ),
  // Add more mock trips...
]);
