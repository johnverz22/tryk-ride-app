import 'package:dartz/dartz.dart';
import 'package:user/features/core/errors/failures.dart';
import 'package:user/features/ride/domain/entities/driver_location.dart';
import 'package:user/features/ride/domain/repositories/ride_repository.dart';

class StreamDriverLocation {
  final RideRepository repository;

  StreamDriverLocation(this.repository);

  // The call method allows the use case to be called like a function
  Stream<Either<Failure, DriverLocationEntity>> call(int rideId) {
    return repository.streamDriverLocation(rideId);
  }
}
