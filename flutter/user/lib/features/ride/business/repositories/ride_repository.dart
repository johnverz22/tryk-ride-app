import 'package:dartz/dartz.dart';
import '../entities/ride_entity.dart';
import '../entities/driver_entity.dart';
import '../../../../core/errors/failures.dart';

abstract class RideRepository {
  // Ride booking flow
  Future<Either<Failure, RideEntity>> requestRide({
    required RideType rideType,
    required String pickupAddress,
    required double pickupLatitude,
    required double pickupLongitude,
    required String dropoffAddress,
    required double dropoffLatitude,
    required double dropoffLongitude,
    String? paymentMethod,
  });

  Future<Either<Failure, RideEntity>> cancelRide(String rideId);
  Future<Either<Failure, RideEntity>> getRideDetails(String rideId);
  Future<Either<Failure, List<RideEntity>>> getUserRides({int page = 1, int limit = 20});

  // Real-time tracking
  Stream<RideEntity> trackRide(String rideId);
  Stream<DriverEntity> trackDriver(String driverId);

  // Available drivers
  Future<Either<Failure, List<DriverEntity>>> getNearbyDrivers({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    RideType? rideType,
  });

  // Fare calculation
  Future<Either<Failure, double>> calculateFare({
    required RideType rideType,
    required double pickupLatitude,
    required double pickupLongitude,
    required double dropoffLatitude,
    required double dropoffLongitude,
  });

  // Rating and feedback
  Future<Either<Failure, void>> rateRide({
    required String rideId,
    required int rating,
    String? review,
  });
}