class RideRequest {
  final int id;
  final int userId;
  final int driverId;
  final String pickupAddress;
  final double pickupLatitude;
  final double pickupLongitude;
  final String dropoffAddress;
  final double dropoffLatitude;
  final double dropoffLongitude;
  final DateTime requestedAt;

  final double? distanceInKm;
  final double? durationInMinutes;
  final double? fareAmount;
  final String? paymentMethod;
  final bool isPaid;
  final String? riderName;
  final String? riderProfilePicture;

  RideRequest({
    required this.id,
    required this.userId,
    required this.driverId,
    required this.pickupAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.dropoffAddress,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    required this.requestedAt,
    this.distanceInKm,
    this.durationInMinutes,
    this.fareAmount,
    this.paymentMethod,
    required this.isPaid,
    this.riderName,
    this.riderProfilePicture,
  });

  factory RideRequest.fromJson(Map<String, dynamic> json) {
    return RideRequest(
      id: json['id'],
      userId: json['user_id'],
      driverId: json['driver_info']?['id'] ?? 0,
      pickupAddress: json['pickup_address'],
      pickupLatitude: json['pickup_latitude'].toDouble(),
      pickupLongitude: json['pickup_longitude'].toDouble(),
      dropoffAddress: json['dropoff_address'],
      dropoffLatitude: json['dropoff_latitude'].toDouble(),
      dropoffLongitude: json['dropoff_longitude'].toDouble(),
      requestedAt: DateTime.parse(json['requested_at']),
      distanceInKm: json['distance_km'] != null
          ? (json['distance_km'] as num).toDouble()
          : null,
      durationInMinutes: json['duration_minutes'] != null
          ? (json['duration_minutes'] as num).toDouble()
          : null,
      fareAmount: json['fare_amount'] != null
          ? (json['fare_amount'] as num).toDouble()
          : null,
      paymentMethod: json['payment_method'],
      isPaid: json['is_paid'] ?? false,
      riderName: json['user']?['name'],
      riderProfilePicture: json['user']?['profile_picture'],
    );
  }
}
