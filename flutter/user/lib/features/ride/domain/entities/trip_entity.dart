import 'package:google_maps_flutter/google_maps_flutter.dart'; // Assuming LatLng is a domain concept

class TripEntity {
  final int id;
  final String pickupAddress;
  final String dropoffAddress;
  final double fareAmount;
  final String paymentMethod;
  final String? driverName;
  final int? riderRating;
  final String statusName;
  final DateTime requestedAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final DateTime? canceledAt;

  final LatLng? pickupCoordinates;
  final LatLng? dropoffCoordinates;

  TripEntity({
    required this.id,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.fareAmount,
    required this.paymentMethod,
    this.driverName,
    this.riderRating,
    required this.statusName,
    required this.requestedAt,
    this.acceptedAt,
    this.completedAt,
    this.canceledAt,
    this.pickupCoordinates,
    this.dropoffCoordinates,
  });

  String get formattedTime {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(
      requestedAt.year,
      requestedAt.month,
      requestedAt.day,
    );

    if (msgDate == today) {
      return '${requestedAt.hour}:${requestedAt.minute.toString().padLeft(2, '0')}';
    } else if (today.difference(msgDate).inDays == 1) {
      return 'Yesterday';
    } else {
      return '${requestedAt.month}/${requestedAt.day}';
    }
  }

  bool get isOngoing {
    final ongoingStatuses = [
      'Accepted',
      'Driver En Route',
      'Ride Started Awaiting User Confirmation',
      'Ride in Progress',
      'Ride Completed Awaiting User Confirmation',
    ];
    return ongoingStatuses.contains(statusName);
  }

  bool get isCompleted => statusName == 'Completed';
  bool get isCancelled => statusName == 'Cancelled';
}
