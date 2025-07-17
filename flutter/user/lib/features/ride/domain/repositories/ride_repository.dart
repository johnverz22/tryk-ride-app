import 'package:dartz/dartz.dart';
import 'package:user/features/core/errors/failures.dart';
import 'package:user/features/ride/domain/entities/driver_location.dart';
import 'package:user/features/ride/domain/entities/ride.dart';
import 'package:user/features/ride/domain/entities/ride_details.dart';

abstract class RideRepository {
  Future<Either<Failure, int>> requestRide(Ride request);
  Future<Either<Failure, void>> cancelRide(int rideId);
  Future<Either<Failure, RideDetails>> fetchRideDetails(int rideId);
  Future<Either<Failure, void>> submitRideRating(
    int rideId,
    int rating,
    String? review,
  );

  Stream<Either<Failure, DriverLocationEntity>> streamDriverLocation(
    int rideId,
  );
}
