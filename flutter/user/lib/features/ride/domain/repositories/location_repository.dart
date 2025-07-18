import 'package:dartz/dartz.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:user/features/core/errors/failures.dart';
import '../entities/location_entity.dart';

abstract class LocationRepository {
  Future<Either<Failure, List<LocationEntity>>> fetchSavedLocations(
    String token,
  );
  Future<Either<Failure, LocationEntity>> addSavedLocation(
    String token,
    String name,
    LatLng latLng,
  );
  Future<Either<Failure, LocationEntity>> updateSavedLocation(
    String token,
    int id,
    String name,
    LatLng latLng,
  );
  Future<Either<Failure, Unit>> deleteSavedLocation(String token, int id);
}
