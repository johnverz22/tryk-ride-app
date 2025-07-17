import 'package:dartz/dartz.dart';

import 'package:user/features/core/errors/failures.dart';

import '../entities/ride.dart';
import '../repositories/ride_repository.dart';

class RequestRide {
  final RideRepository repository;

  RequestRide(this.repository);

  Future<Either<Failure, int>> call(Ride request) {
    return repository.requestRide(request);
  }
}
