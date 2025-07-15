import '../repositories/ride_repository.dart';

class CancelRide {
  final RideRepository repository;

  CancelRide(this.repository);

  Future<void> call(int rideId) {
    return repository.cancelRide(rideId);
  }
}
