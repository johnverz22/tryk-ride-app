import '../../../../../core/constants/constants.dart';
import '../../business/entities/driver_entity.dart';

class DriverModel extends DriverEntity {
  const DriverModel({
    required String id,
    required String fullName,
    required String phoneNumber,
    required String email,
    String? profilePhotoUrl,
    required String licenseNumber,
    String? vehicleModel,
    String? vehiclePlate,
    String? vehicleColor,
    bool isOnline = false,
    bool isVerified = false,
    double? currentLatitude,
    double? currentLongitude,
    double rating = 5.0,
    int totalTrips = 0,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(
          id: id,
          fullName: fullName,
          phoneNumber: phoneNumber,
          email: email,
          profilePhotoUrl: profilePhotoUrl,
          licenseNumber: licenseNumber,
          vehicleModel: vehicleModel,
          vehiclePlate: vehiclePlate,
          vehicleColor: vehicleColor,
          isOnline: isOnline,
          isVerified: isVerified,
          currentLatitude: currentLatitude,
          currentLongitude: currentLongitude,
          rating: rating,
          totalTrips: totalTrips,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory DriverModel.fromJson({required Map<String, dynamic> json}) {
    return DriverModel(
      id: json[kDriverId]?.toString() ?? '',
      fullName: json[kDriverFullName] ?? '',
      phoneNumber: json[kDriverPhoneNumber]?.toString() ?? '',
      email: json[kDriverEmail]?.toString() ?? '',
      profilePhotoUrl: json[kDriverProfilePhotoUrl] as String?,
      licenseNumber: json[kDriverLicenseNumber]?.toString() ?? '',
      vehicleModel: json[kDriverVehicleModel] as String?,
      vehiclePlate: json[kDriverVehiclePlate] as String?,
      vehicleColor: json[kDriverVehicleColor] as String?,
      isOnline: json[kDriverIsOnline] ?? false,
      isVerified: json[kDriverIsVerified] ?? false,
      currentLatitude: (json[kDriverLatitude] as num?)?.toDouble(),
      currentLongitude: (json[kDriverLongitude] as num?)?.toDouble(),
      rating: (json[kDriverRating] as num?)?.toDouble() ?? 5.0,
      totalTrips: json[kDriverTotalTrips] ?? 0,
      createdAt: json[kDriverCreatedAt] != null
          ? DateTime.parse(json[kDriverCreatedAt])
          : DateTime.now(),
      updatedAt: json[kDriverUpdatedAt] != null
          ? DateTime.parse(json[kDriverUpdatedAt])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      kDriverId: id,
      kDriverFullName: fullName,
      kDriverPhoneNumber: phoneNumber,
      kDriverEmail: email,
      kDriverProfilePhotoUrl: profilePhotoUrl,
      kDriverLicenseNumber: licenseNumber,
      kDriverVehicleModel: vehicleModel,
      kDriverVehiclePlate: vehiclePlate,
      kDriverVehicleColor: vehicleColor,
      kDriverIsOnline: isOnline,
      kDriverIsVerified: isVerified,
      kDriverLatitude: currentLatitude,
      kDriverLongitude: currentLongitude,
      kDriverRating: rating,
      kDriverTotalTrips: totalTrips,
      kDriverCreatedAt: createdAt.toIso8601String(),
      kDriverUpdatedAt: updatedAt.toIso8601String(),
    };
  }
}
