import '../entities/ride.dart';
import '../repositories/ride_repository.dart';

class RequestRide {
  final RideRepository repository;

  RequestRide(this.repository);

  Future<int> call(Ride request) {
    return repository.requestRide(request);
  }
}
