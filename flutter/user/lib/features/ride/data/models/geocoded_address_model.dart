import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/place_entity.dart';

class GeocodedAddressModel extends GeocodedAddressEntity {
  const GeocodedAddressModel({
    required super.formattedAddress,
    required super.latLng,
  });

  factory GeocodedAddressModel.fromJson(
    Map<String, dynamic> json,
    LatLng latLng,
  ) {
    return GeocodedAddressModel(
      formattedAddress: json['formatted_address'] as String,
      latLng: latLng,
    );
  }
}
