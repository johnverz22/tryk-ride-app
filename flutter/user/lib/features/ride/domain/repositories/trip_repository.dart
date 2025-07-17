import 'package:dartz/dartz.dart';
import 'package:user/features/core/errors/failures.dart';

import '../entities/trip_entity.dart';

abstract class TripRepository {
  Future<Either<Failure, List<TripEntity>>> getUserTrips(
    String token, {
    int page = 1,
  });
}
