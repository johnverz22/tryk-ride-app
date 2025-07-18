import 'package:dartz/dartz.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:user/features/core/errors/failures.dart';
import '../entities/place_entity.dart';
import '../repositories/place_repository.dart';

class GetPlaceNameFromLatLngUseCase {
  final PlaceRepository repository;
  GetPlaceNameFromLatLngUseCase(this.repository);

  Future<Either<Failure, GeocodedAddressEntity>> call(LatLng latLng) async {
    return await repository.getPlaceNameFromLatLng(latLng);
  }
}
