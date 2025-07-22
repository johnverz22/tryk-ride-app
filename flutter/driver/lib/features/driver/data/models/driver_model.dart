import '../../../../../core/constants/constants.dart';
import '../../domain/entities/driver_entity.dart';

class DriverModel extends DriverEntity {
  const DriverModel({
    required super.id,
    required super.name,
    required super.phone,
    required super.email,
    super.profilePhotoUrl,
    required super.licenseNumber,
    super.vehicleModel,
    super.vehiclePlate,
    super.vehicleColor,
    super.isOnline,
    super.isVerified,
    super.currentLatitude,
    super.currentLongitude,
    super.rating,
    super.totalTrips,
    required super.createdAt,
    required super.updatedAt,
  });

  factory DriverModel.fromJson({required Map<String, dynamic> json}) {
    return DriverModel(
      id: int.tryParse(json[kDriverId].toString()) ?? 0,
      name: json[kDriverFullName] ?? '',
      phone: json[kDriverPhoneNumber]?.toString() ?? '',
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
      kDriverFullName: name,
      kDriverPhoneNumber: phone,
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

  DriverModel copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? profilePhotoUrl,
    String? licenseNumber,
    String? vehicleModel,
    String? vehiclePlate,
    String? vehicleColor,
    bool? isOnline,
    bool? isVerified,
    double? currentLatitude,
    double? currentLongitude,
    double? rating,
    int? totalTrips,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DriverModel(
      // FIX: Use `?? this.id` instead of `!` to avoid crash when id is null
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      isOnline: isOnline ?? this.isOnline,
      isVerified: isVerified ?? this.isVerified,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      rating: rating ?? this.rating,
      totalTrips: totalTrips ?? this.totalTrips,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
