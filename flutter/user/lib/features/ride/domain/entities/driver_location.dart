import 'package:google_maps_flutter/google_maps_flutter.dart';

class DriverLocationEntity {
  final int rideId;
  final int driverId;
  final LatLng coordinates;
  final double? bearing; // Optional: driver direction
  final double? speed; // Optional: driver speed
  final Map<String, dynamic>?
  driverInfo; // Basic driver info (e.g., name, photo URL)

  DriverLocationEntity({
    required this.rideId,
    required this.driverId,
    required this.coordinates,
    this.bearing,
    this.speed,
    this.driverInfo,
  });

  @override
  String toString() {
    return 'DriverLocationEntity(rideId: $rideId, driverId: $driverId, coordinates: $coordinates, bearing: $bearing, speed: $speed)';
  }
}
