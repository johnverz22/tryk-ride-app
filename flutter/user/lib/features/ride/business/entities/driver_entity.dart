import 'package:equatable/equatable.dart';

enum DriverStatus {
  offline,
  online,
  busy,
  enRoute,
}

class DriverEntity extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String? profilePhotoUrl;
  final double rating;
  final int totalTrips;
  final DriverStatus status;
  
  // Location
  final double? currentLatitude;
  final double? currentLongitude;
  
  // Vehicle info
  final String? vehicleType;
  final String? vehicleBrand;
  final String? vehicleModel;
  final String? licensePlate;
  
  // Real-time info
  final int? estimatedArrivalMinutes;
  final double? distanceFromUser;

  const DriverEntity({
    required this.id,
    required this.name,
    required this.phone,
    this.profilePhotoUrl,
    required this.rating,
    required this.totalTrips,
    required this.status,
    this.currentLatitude,
    this.currentLongitude,
    this.vehicleType,
    this.vehicleBrand,
    this.vehicleModel,
    this.licensePlate,
    this.estimatedArrivalMinutes,
    this.distanceFromUser,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        profilePhotoUrl,
        rating,
        totalTrips,
        status,
        currentLatitude,
        currentLongitude,
        vehicleType,
        vehicleBrand,
        vehicleModel,
        licensePlate,
        estimatedArrivalMinutes,
        distanceFromUser,
      ];

  bool get isAvailable => status == DriverStatus.online;
  
  String get vehicleInfo {
    if (vehicleBrand != null && vehicleModel != null) {
      return '$vehicleBrand $vehicleModel';
    }
    return vehicleType ?? 'Vehicle';
  }

  DriverEntity copyWith({
    String? id,
    String? name,
    String? phone,
    String? profilePhotoUrl,
    double? rating,
    int? totalTrips,
    DriverStatus? status,
    double? currentLatitude,
    double? currentLongitude,
    String? vehicleType,
    String? vehicleBrand,
    String? vehicleModel,
    String? licensePlate,
    int? estimatedArrivalMinutes,
    double? distanceFromUser,
  }) {
    return DriverEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      rating: rating ?? this.rating,
      totalTrips: totalTrips ?? this.totalTrips,
      status: status ?? this.status,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleBrand: vehicleBrand ?? this.vehicleBrand,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      licensePlate: licensePlate ?? this.licensePlate,
      estimatedArrivalMinutes: estimatedArrivalMinutes ?? this.estimatedArrivalMinutes,
      distanceFromUser: distanceFromUser ?? this.distanceFromUser,
    );
  }
}