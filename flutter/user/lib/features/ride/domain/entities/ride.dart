class Ride {
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

  Ride({
    required this.pickupAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.dropoffAddress,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    required this.paymentMethod,
    required this.searchRadiusKm,
    DateTime? requestedAt,
    required this.distanceKm,
    required this.durationMinutes,
    required this.fareAmount,
  }) : requestedAt = requestedAt ?? DateTime.now();
}
