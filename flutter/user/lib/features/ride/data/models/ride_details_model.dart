import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:user/features/ride/domain/entities/ride_details.dart';

class RideDetailsModel extends RideDetails {
  RideDetailsModel({
    required Map<String, dynamic> ride,
    required Map<String, dynamic> driver,
    required LatLng pickup,
    required LatLng destination,
    required String status,
  }) : super(
         ride: ride,
         driver: driver,
         pickup: pickup,
         destination: destination,
         status: status,
       );

  factory RideDetailsModel.fromJson(Map<String, dynamic> json) {
    final driver = (json['driver'] ?? {}) as Map<String, dynamic>;

    final pickup = LatLng(
      double.tryParse(json['pickup_latitude'].toString()) ?? 0.0,
      double.tryParse(json['pickup_longitude'].toString()) ?? 0.0,
    );

    final destination = LatLng(
      double.tryParse(json['dropoff_latitude'].toString()) ?? 0.0,
      double.tryParse(json['dropoff_longitude'].toString()) ?? 0.0,
    );

    final status =
        json['status']?['name']?.toString().toLowerCase() ?? 'unknown';

    return RideDetailsModel(
      ride: json,
      driver: driver,
      pickup: pickup,
      destination: destination,
      status: status,
    );
  }
}
