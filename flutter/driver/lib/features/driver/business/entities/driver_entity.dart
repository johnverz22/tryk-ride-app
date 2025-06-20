class DriverEntity {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String email;
  final String? profilePhotoUrl;
  final String licenseNumber;
  final String? vehicleModel;
  final String? vehiclePlate;
  final String? vehicleColor;
  final bool isOnline;
  final bool isVerified;
  final double? currentLatitude;
  final double? currentLongitude;
  final double rating;
  final int totalTrips;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DriverEntity({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    this.profilePhotoUrl,
    required this.licenseNumber,
    this.vehicleModel,
    this.vehiclePlate,
    this.vehicleColor,
    this.isOnline = false,
    this.isVerified = false,
    this.currentLatitude,
    this.currentLongitude,
    this.rating = 5.0,
    this.totalTrips = 0,
    required this.createdAt,
    required this.updatedAt,
  });
}
