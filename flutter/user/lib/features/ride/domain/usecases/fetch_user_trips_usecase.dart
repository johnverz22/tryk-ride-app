import 'package:dartz/dartz.dart';
import 'package:user/features/core/errors/failures.dart';
import '../entities/trip_entity.dart';
import '../repositories/trip_repository.dart';

class FetchUserTripsUseCase {
  final TripRepository repository;

  FetchUserTripsUseCase({required this.repository});

  Future<Either<Failure, List<TripEntity>>> call(
    String token, {
    int page = 1,
  }) async {
    return await repository.getUserTrips(token, page: page);
  }
}
