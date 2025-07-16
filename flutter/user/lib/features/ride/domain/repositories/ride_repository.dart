import 'package:user/features/ride/domain/entities/ride.dart';
import 'package:user/features/ride/domain/entities/ride_details.dart';

abstract class RideRepository {
  Future<int> requestRide(Ride model);
  Future<void> cancelRide(int rideId);
  Future<RideDetails> fetchRideDetails(int rideId);
}
