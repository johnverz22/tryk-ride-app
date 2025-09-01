import 'package:equatable/equatable.dart';

enum RideStatus {
  requested,
  accepted,
  driverEnRoute,
  arrived,
  inProgress,
  completed,
  cancelled,
}

enum RideType {
  economy,
  comfort,
  premium,
}

class RideEntity extends Equatable {
  final String id;
  final String userId;
  final String? driverId;
  final RideStatus status;
  final RideType type;
  
  // Location details
  final String pickupAddress;
  final double pickupLatitude;
  final double pickupLongitude;
  final String dropoffAddress;
  final double dropoffLatitude;
  final double dropoffLongitude;
  
  // Timing
  final DateTime requestedAt;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  
  // Trip details
  final double? distanceKm;
  final double? durationMinutes;
  final double fareAmount;
  final String? paymentMethod;
  final bool isPaid;
  
  // Ratings
  final int? riderRating;
  final String? riderReview;
  final int? driverRating;
  final String? driverReview;
  
  // Real-time tracking
  final double? currentDriverLatitude;
  final double? currentDriverLongitude;
  final int? estimatedArrivalMinutes;

  const RideEntity({
    required this.id,
    required this.userId,
    this.driverId,
    required this.status,
    required this.type,
    required this.pickupAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.dropoffAddress,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    required this.requestedAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.completedAt,
    this.cancelledAt,
    this.distanceKm,
    this.durationMinutes,
    required this.fareAmount,
    this.paymentMethod,
    this.isPaid = false,
    this.riderRating,
    this.riderReview,
    this.driverRating,
    this.driverReview,
    this.currentDriverLatitude,
    this.currentDriverLongitude,
    this.estimatedArrivalMinutes,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        driverId,
        status,
        type,
        pickupAddress,
        pickupLatitude,
        pickupLongitude,
        dropoffAddress,
        dropoffLatitude,
        dropoffLongitude,
        requestedAt,
        acceptedAt,
        pickedUpAt,
        completedAt,
        cancelledAt,
        distanceKm,
        durationMinutes,
        fareAmount,
        paymentMethod,
        isPaid,
        riderRating,
        riderReview,
        driverRating,
        driverReview,
        currentDriverLatitude,
        currentDriverLongitude,
        estimatedArrivalMinutes,
      ];

  RideEntity copyWith({
    String? id,
    String? userId,
    String? driverId,
    RideStatus? status,
    RideType? type,
    String? pickupAddress,
    double? pickupLatitude,
    double? pickupLongitude,
    String? dropoffAddress,
    double? dropoffLatitude,
    double? dropoffLongitude,
    DateTime? requestedAt,
    DateTime? acceptedAt,
    DateTime? pickedUpAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    double? distanceKm,
    double? durationMinutes,
    double? fareAmount,
    String? paymentMethod,
    bool? isPaid,
    int? riderRating,
    String? riderReview,
    int? driverRating,
    String? driverReview,
    double? currentDriverLatitude,
    double? currentDriverLongitude,
    int? estimatedArrivalMinutes,
  }) {
    return RideEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      driverId: driverId ?? this.driverId,
      status: status ?? this.status,
      type: type ?? this.type,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      dropoffLatitude: dropoffLatitude ?? this.dropoffLatitude,
      dropoffLongitude: dropoffLongitude ?? this.dropoffLongitude,
      requestedAt: requestedAt ?? this.requestedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      distanceKm: distanceKm ?? this.distanceKm,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      fareAmount: fareAmount ?? this.fareAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isPaid: isPaid ?? this.isPaid,
      riderRating: riderRating ?? this.riderRating,
      riderReview: riderReview ?? this.riderReview,
      driverRating: driverRating ?? this.driverRating,
      driverReview: driverReview ?? this.driverReview,
      currentDriverLatitude: currentDriverLatitude ?? this.currentDriverLatitude,
      currentDriverLongitude: currentDriverLongitude ?? this.currentDriverLongitude,
      estimatedArrivalMinutes: estimatedArrivalMinutes ?? this.estimatedArrivalMinutes,
    );
  }
}