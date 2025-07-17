import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:user/features/ride/domain/entities/driver_location.dart';

class DriverLocationModel extends DriverLocationEntity {
  DriverLocationModel({
    required super.rideId,
    required super.driverId,
    required super.coordinates,
    super.bearing,
    super.speed,
    super.driverInfo,
  });

  factory DriverLocationModel.fromJson(
    int rideId,
    int driverId,
    Map<String, dynamic> json,
  ) {
    final latRaw = json['latitude'];
    final lngRaw = json['longitude'];
    final bearing = json['bearing']; // Assuming backend sends bearing
    final speed = json['speed']; // Assuming backend sends speed

    final lat = latRaw is num
        ? latRaw.toDouble()
        : double.tryParse(latRaw.toString()) ?? 0.0;
    final lng = lngRaw is num
        ? lngRaw.toDouble()
        : double.tryParse(lngRaw.toString()) ?? 0.0;

    return DriverLocationModel(
      rideId: rideId,
      driverId: driverId,
      coordinates: LatLng(lat, lng),
      bearing: bearing is num ? bearing.toDouble() : null,
      speed: speed is num ? speed.toDouble() : null,
      driverInfo:
          json['driver_info']
              as Map<String, dynamic>?, // If driver info is embedded
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ride_id': rideId,
      'driver_id': driverId,
      'latitude': coordinates.latitude,
      'longitude': coordinates.longitude,
      if (bearing != null) 'bearing': bearing,
      if (speed != null) 'speed': speed,
      if (driverInfo != null) 'driver_info': driverInfo,
    };
  }
}
