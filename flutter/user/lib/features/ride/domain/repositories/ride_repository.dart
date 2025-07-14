import '../entities/ride_request.dart';

abstract class RideRepository {
  Future<void> requestRide(RideRequest request);
}
