import 'package:user/features/ride/domain/entities/ride.dart';

abstract class RideRepository {
  Future<int> requestRide(Ride model);
  Future<void> cancelRide(int rideId);
}
