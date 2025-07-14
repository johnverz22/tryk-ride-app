import 'package:user/features/ride/domain/entities/ride_request.dart';

class RideRequestModel {
  final String pickupAddress;
  final double pickupLatitude;
  final double pickupLongitude;
  final String dropoffAddress;
  final double dropoffLatitude;
  final double dropoffLongitude;
  final String paymentMethod;
  final int searchRadiusKm;
  final DateTime requestedAt;

  RideRequestModel({
    required this.pickupAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.dropoffAddress,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    required this.paymentMethod,
    required this.searchRadiusKm,
    required this.requestedAt,
  });

  /// Converts a domain entity to model
  factory RideRequestModel.fromEntity(RideRequest e) {
    return RideRequestModel(
      pickupAddress: e.pickupAddress,
      pickupLatitude: e.pickupLatitude,
      pickupLongitude: e.pickupLongitude,
      dropoffAddress: e.dropoffAddress,
      dropoffLatitude: e.dropoffLatitude,
      dropoffLongitude: e.dropoffLongitude,
      paymentMethod: e.paymentMethod,
      searchRadiusKm: e.searchRadiusKm,
      requestedAt: e.requestedAt,
    );
  }

  /// Converts a JSON response to model
  factory RideRequestModel.fromJson(Map<String, dynamic> json) {
    return RideRequestModel(
      pickupAddress: json['pickup_address'] as String,
      pickupLatitude: (json['pickup_latitude'] as num).toDouble(),
      pickupLongitude: (json['pickup_longitude'] as num).toDouble(),
      dropoffAddress: json['dropoff_address'] as String,
      dropoffLatitude: (json['dropoff_latitude'] as num).toDouble(),
      dropoffLongitude: (json['dropoff_longitude'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String,
      searchRadiusKm: json['search_radius_km'] as int,
      requestedAt: DateTime.parse(json['requested_at'] as String),
    );
  }

  /// Converts model to JSON for API request
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
    };
  }
}
