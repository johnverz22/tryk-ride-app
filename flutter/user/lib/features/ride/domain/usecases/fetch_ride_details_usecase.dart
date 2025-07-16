import '../entities/ride_details.dart';
import '../repositories/ride_repository.dart';

class FetchRideDetails {
  final RideRepository repository;

  FetchRideDetails(this.repository);

  Future<RideDetails> call(int rideId) {
    return repository.fetchRideDetails(rideId);
  }
}
