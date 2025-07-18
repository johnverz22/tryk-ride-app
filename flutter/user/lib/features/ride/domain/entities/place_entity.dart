import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PlaceSuggestionEntity extends Equatable {
  final String placeId;
  final String description;

  const PlaceSuggestionEntity({
    required this.placeId,
    required this.description,
  });

  @override
  List<Object?> get props => [placeId, description];
}

class PlaceDetailsEntity extends Equatable {
  final String placeId;
  final String name;
  final LatLng latLng;
  final String? formattedAddress;

  const PlaceDetailsEntity({
    required this.placeId,
    required this.name,
    required this.latLng,
    this.formattedAddress,
  });

  @override
  List<Object?> get props => [placeId, name, latLng, formattedAddress];
}

// Represents a reverse geocoded address
class GeocodedAddressEntity extends Equatable {
  final String formattedAddress;
  final LatLng latLng;

  const GeocodedAddressEntity({
    required this.formattedAddress,
    required this.latLng,
  });

  @override
  List<Object?> get props => [formattedAddress, latLng];
}
