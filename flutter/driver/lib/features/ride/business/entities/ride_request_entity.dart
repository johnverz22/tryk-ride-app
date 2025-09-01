import 'package:equatable/equatable.dart';

enum RideRequestStatus {
  pending,
  accepted,
  declined,
  expired,
}

class RideRequestEntity extends Equatable {
  final String id;
  final String userId;
  final String userNa me;
  final String? userPhotoUrl;
  final double userRating;
  
  // Location details
  final String pickupAddress;
  final double pickupLatitude;
  final double pickupLongitude;
  final String dropoffAddress;
  final double dropoffLatitude;
  final double dropoffLongitude;
  
  // Trip details
  final String rideType;
  final double fareAmount;
  final double distanceKm;
  final int estimatedDurationMinutes;
  
  // Request details
  final DateTime requestedAt;
  final DateTime expiresAt;
  final RideRequestStatus status;
  
  // Distance from driver
  final double? distanceFromDriver;

  const RideRequestEntity({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.userRating,
    required this.pickupAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.dropoffAddress,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    required this.rideType,
    required this.fareAmount,
    required this.distanceKm,
    required this.estimatedDurationMinutes,
    required this.requestedAt,
    required this.expiresAt,
    required this.status,
    this.distanceFromDriver,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        userPhotoUrl,
        userRating,
        pickupAddress,
        pickupLatitude,
        pickupLongitude,
        dropoffAddress,
        dropoffLatitude,
        dropoffLongitude,
        rideType,
        fareAmount,
        distanceKm,
        estimatedDurationMinutes,
        requestedAt,
        expiresAt,
        status,
        distanceFromDriver,
      ];

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isPending => status == RideRequestStatus.pending && !isExpired;
  
  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return Duration.zero;
    return expiresAt.difference(now);
  }

  RideRequestEntity copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    double? userRating,
    String? pickupAddress,
    double? pickupLatitude,
    double? pickupLongitude,
    String? dropoffAddress,
    double? dropoffLatitude,
    double? dropoffLongitude,
    String? rideType,
    double? fareAmount,
    double? distanceKm,
    int? estimatedDurationMinutes,
    DateTime? requestedAt,
    DateTime? expiresAt,
    RideRequestStatus? status,
    double? distanceFromDriver,
  }) {
    return RideRequestEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      userRating: userRating ?? this.userRating,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      dropoffLatitude: dropoffLatitude ?? this.dropoffLatitude,
      dropoffLongitude: dropoffLongitude ?? this.dropoffLongitude,
      rideType: rideType ?? this.rideType,
      fareAmount: fareAmount ?? this.fareAmount,
      distanceKm: distanceKm ?? this.distanceKm,
      estimatedDurationMinutes: estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      requestedAt: requestedAt ?? this.requestedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      distanceFromDriver: distanceFromDriver ?? this.distanceFromDriver,
    );
  }
}