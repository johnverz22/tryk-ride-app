import 'package:dartz/dartz.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:user/features/core/errors/failures.dart';
import '../entities/location_entity.dart';
import '../repositories/location_repository.dart';

class UpdateSavedLocationUseCase {
  final LocationRepository repository;
  UpdateSavedLocationUseCase(this.repository);

  Future<Either<Failure, LocationEntity>> call(
    String token,
    int id,
    String name,
    LatLng latLng,
  ) async {
    return await repository.updateSavedLocation(token, id, name, latLng);
  }
}
