import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/location_entity.dart';

class LocationModel extends LocationEntity {
  const LocationModel({
    required super.id,
    required super.name,
    required super.latLng,
    required super.icon,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] as int,
      name: json['location_name'] as String,
      latLng: LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      ),
      icon: Icons.star,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location_name': name,
      'latitude': latLng.latitude,
      'longitude': latLng.longitude,
    };
  }
}
