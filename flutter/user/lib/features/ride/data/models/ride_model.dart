import 'package:user/features/ride/domain/entities/ride.dart';

class RideModel {
  final String pickupAddress;
  final double pickupLatitude;
  final double pickupLongitude;
  final String dropoffAddress;
  final double dropoffLatitude;
  final double dropoffLongitude;
  final String paymentMethod;
  final int searchRadiusKm;
  final DateTime requestedAt;
  final double distanceKm;
  final double durationMinutes;
  final double fareAmount;

  RideModel({
    required this.pickupAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.dropoffAddress,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    required this.paymentMethod,
    required this.searchRadiusKm,
    required this.requestedAt,
    required this.distanceKm,
    required this.durationMinutes,
    required this.fareAmount,
  });

  factory RideModel.fromEntity(Ride e) {
    return RideModel(
      pickupAddress: e.pickupAddress,
      pickupLatitude: e.pickupLatitude,
      pickupLongitude: e.pickupLongitude,
      dropoffAddress: e.dropoffAddress,
      dropoffLatitude: e.dropoffLatitude,
      dropoffLongitude: e.dropoffLongitude,
      paymentMethod: e.paymentMethod,
      searchRadiusKm: e.searchRadiusKm,
      requestedAt: e.requestedAt,
      distanceKm: e.distanceKm,
      durationMinutes: e.durationMinutes,
      fareAmount: e.fareAmount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "pickup_address": pickupAddress,
      "pickup_latitude": pickupLatitude,
      "pickup_longitude": pickupLongitude,
      "dropoff_address": dropoffAddress,
      "dropoff_latitude": dropoffLatitude,
      "dropoff_longitude": dropoffLongitude,
      "payment_method": paymentMethod,
      "search_radius_km": searchRadiusKm,
      "requested_at": requestedAt.toIso8601String(),
      "distance_km": distanceKm,
      "duration_minutes": durationMinutes,
      "fare_amount": fareAmount,
    };
  }
}
