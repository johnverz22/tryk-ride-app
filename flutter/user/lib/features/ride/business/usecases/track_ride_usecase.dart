import '../entities/ride_entity.dart';
import '../repositories/ride_repository.dart';

class TrackRideUseCase {
  final RideRepository repository;

  TrackRideUseCase(this.repository);

  Stream<RideEntity> call(String rideId) {
    return repository.trackRide(rideId);
  }
}