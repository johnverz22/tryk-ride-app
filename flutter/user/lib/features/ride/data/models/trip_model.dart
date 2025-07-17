// user/features/ride/data/models/trip_model.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/trip_entity.dart';

class TripModel extends TripEntity {
  TripModel({
    required super.id,
    required super.pickupAddress,
    required super.dropoffAddress,
    required super.fareAmount,
    required super.paymentMethod,
    super.driverName,
    super.riderRating,
    required super.statusName,
    required super.requestedAt,
    super.acceptedAt,
    super.completedAt,
    super.canceledAt,
    super.pickupCoordinates,
    super.dropoffCoordinates,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as Map<String, dynamic>?;
    final driverName =
        json['driver'] as String?; // Directly from 'driver' field
    final riderRating = json['rider_rating'];

    // Safely parse dates
    DateTime? parseDate(dynamic dateString) {
      if (dateString == null) return null;
      try {
        return DateTime.parse(dateString.toString());
      } catch (e) {
        return null;
      }
    }

    // Safely parse coordinates
    LatLng? parseCoordinates(dynamic lat, dynamic lng) {
      if (lat == null || lng == null) return null;
      try {
        return LatLng(
          double.parse(lat.toString()),
          double.parse(lng.toString()),
        );
      } catch (e) {
        return null;
      }
    }

    return TripModel(
      id: json['id'] as int,
      pickupAddress: json['pickup_address'] as String,
      dropoffAddress: json['dropoff_address'] as String,
      fareAmount: (json['fare_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? 'Unknown',
      driverName: driverName,
      riderRating: (riderRating as num?)?.toInt(),
      statusName:
          status?['name'] as String? ??
          'Unknown', // Access 'name' from 'status' object
      requestedAt: parseDate(
        json['requested_at'],
      )!, // Assuming requested_at is always present
      acceptedAt: parseDate(json['accepted_at']),
      completedAt: parseDate(json['completed_at']),
      canceledAt: parseDate(json['canceled_at']),
      // Assuming these are directly in the main ride object for now
      // If they are not, you'll need to adjust the JSON parsing
      pickupCoordinates: parseCoordinates(
        json['pickup_latitude'],
        json['pickup_longitude'],
      ),
      dropoffCoordinates: parseCoordinates(
        json['dropoff_latitude'],
        json['dropoff_longitude'],
      ),
    );
  }
}
