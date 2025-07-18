import 'package:dartz/dartz.dart';
import 'package:user/features/core/errors/failures.dart';
import '../entities/location_entity.dart';
import '../repositories/location_repository.dart';

class FetchSavedLocationsUseCase {
  final LocationRepository repository;
  FetchSavedLocationsUseCase(this.repository);

  Future<Either<Failure, List<LocationEntity>>> call(String token) async {
    return await repository.fetchSavedLocations(token);
  }
}
