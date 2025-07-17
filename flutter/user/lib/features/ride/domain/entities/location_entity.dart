import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart'; // For IconData

class LocationEntity extends Equatable {
  final int id;
  final String name;
  final LatLng latLng;
  final IconData icon; // Storing icon directly in entity for simplicity

  const LocationEntity({
    required this.id,
    required this.name,
    required this.latLng,
    required this.icon,
  });

  @override
  List<Object?> get props => [id, name, latLng, icon];
}
