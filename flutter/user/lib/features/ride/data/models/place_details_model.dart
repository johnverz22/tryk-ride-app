import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/place_entity.dart';

class PlaceDetailsModel extends PlaceDetailsEntity {
  const PlaceDetailsModel({
    required super.placeId,
    required super.name,
    required super.latLng,
    super.formattedAddress,
  });

  factory PlaceDetailsModel.fromJson(Map<String, dynamic> json) {
    final location = json['geometry']['location'];
    return PlaceDetailsModel(
      placeId: json['place_id'] as String,
      name: json['name'] as String,
      latLng: LatLng(location['lat'] as double, location['lng'] as double),
      formattedAddress: json['formatted_address'] as String?,
    );
  }
}
