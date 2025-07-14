// domain/usecases/request_ride.dart

import '../entities/ride_request.dart';
import '../repositories/ride_repository.dart';

class RequestRide {
  final RideRepository repository;

  RequestRide(this.repository);

  Future<void> call(RideRequest request) {
    return repository.requestRide(request);
  }
}
