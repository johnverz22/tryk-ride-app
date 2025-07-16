import 'package:google_maps_flutter/google_maps_flutter.dart';

class RideDetails {
  final Map<String, dynamic> ride;
  final Map<String, dynamic> driver;
  final LatLng pickup;
  final LatLng destination;
  final String status;

  RideDetails({
    required this.ride,
    required this.driver,
    required this.pickup,
    required this.destination,
    required this.status,
  });
}
