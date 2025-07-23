import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

@immutable
class RouteDetails {
  final List<LatLng> polylinePoints;
  final double distanceInKm;
  final double durationInMinutes;
  final double fare;

  const RouteDetails({
    required this.polylinePoints,
    required this.distanceInKm,
    required this.durationInMinutes,
    required this.fare,
  });
}
