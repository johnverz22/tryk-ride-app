import 'package:dartz/dartz.dart';

import 'package:user/features/core/errors/failures.dart';

import '../entities/ride_details.dart';
import '../repositories/ride_repository.dart';

class FetchRideDetails {
  final RideRepository repository;

  FetchRideDetails(this.repository);

  Future<Either<Failure, RideDetails>> call(int rideId) {
    return repository.fetchRideDetails(rideId);
  }
}
