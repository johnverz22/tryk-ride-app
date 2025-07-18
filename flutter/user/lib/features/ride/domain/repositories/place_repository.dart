import 'package:dartz/dartz.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:user/features/core/errors/failures.dart';
import '../entities/place_entity.dart';

abstract class PlaceRepository {
  Future<Either<Failure, List<PlaceSuggestionEntity>>> searchPlaces(
    String query,
  );
  Future<Either<Failure, PlaceDetailsEntity>> getPlaceDetails(String placeId);
  Future<Either<Failure, GeocodedAddressEntity>> getPlaceNameFromLatLng(
    LatLng latLng,
  );
}
