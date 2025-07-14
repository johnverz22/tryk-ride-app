class RideRequest {
  final String pickupAddress;
  final double pickupLatitude;
  final double pickupLongitude;
  final String dropoffAddress;
  final double dropoffLatitude;
  final double dropoffLongitude;
  final String paymentMethod;
  final int searchRadiusKm;
  final DateTime requestedAt;

  RideRequest({
    required this.pickupAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.dropoffAddress,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    required this.paymentMethod,
    this.searchRadiusKm = 10,
    DateTime? requestedAt,
  }) : requestedAt = requestedAt ?? DateTime.now();
}
