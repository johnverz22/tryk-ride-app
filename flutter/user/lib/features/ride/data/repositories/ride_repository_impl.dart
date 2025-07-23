import 'package:dartz/dartz.dart';
import 'package:google_maps_flutter_platform_interface/src/types/location.dart';
import 'package:user/features/core/errors/exceptions.dart';
import 'package:user/features/core/errors/failures.dart';
import 'package:user/features/ride/data/datasources/ride_remote_datasource.dart';
import 'package:user/features/ride/domain/entities/driver_location.dart';
import 'package:user/features/ride/domain/entities/route_details.dart';
import 'package:user/features/ride/domain/repositories/ride_repository.dart';
import 'package:user/features/ride/domain/entities/ride.dart';
import 'package:user/features/ride/data/models/ride_model.dart';
import 'package:user/features/ride/domain/entities/ride_details.dart';

class RideRepositoryImpl implements RideRepository {
  final RideRemoteDatasource remote;

  RideRepositoryImpl(this.remote);

  @override
  Future<Either<Failure, int>> requestRide(Ride request) async {
    try {
      final model = RideModel.fromEntity(request);
      final rideId = await remote.requestRide(model);
      return Right(rideId);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (_) {
      return Left(NoInternetFailure());
    } catch (e) {
      return Left(
        UnexpectedFailure(e.toString()),
      ); // Catch any other unexpected errors
    }
  }

  @override
  Future<Either<Failure, void>> cancelRide(int rideId) async {
    try {
      await remote.cancelRide(rideId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (_) {
      return Left(NoInternetFailure());
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RideDetails>> fetchRideDetails(int rideId) async {
    try {
      final rideDetails = await remote.fetchRideDetails(rideId);
      return Right(rideDetails);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (_) {
      return Left(NoInternetFailure());
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> submitRideRating(
    int rideId,
    int rating,
    String? review,
  ) async {
    try {
      await remote.submitRideRating(rideId, rating, review);
      return const Right(null); // Success, no data to return
    } on ServerException catch (e) {
      return Left(
        ServerFailure(message: e.message),
      ); // Map ServerException to ServerFailure
    } on NetworkException catch (_) {
      return Left(
        NoInternetFailure(),
      ); // Map NetworkException to NoInternetFailure
    } catch (e) {
      // Catch any other unexpected errors during the process
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, DriverLocationEntity>> streamDriverLocation(
    int rideId,
  ) {
    // TODO: implement streamDriverLocation
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, RouteDetails>> getRouteDetails(
    LatLng from,
    LatLng to,
  ) async {
    try {
      final result = await remote.getPolylineRoute(from, to);

      final distanceInKm = (result.totalDistanceValue ?? 0) / 1000.0;
      final durationInMinutes = (result.totalDurationValue ?? 0) / 60.0;
      final polylineCoordinates = result.points
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();

      // Here we are creating a RouteDetails entity but without the fare,
      // as fare calculation is a business rule in the use case.
      final routeDetails = RouteDetails(
        distanceInKm: distanceInKm,
        durationInMinutes: durationInMinutes,
        fare: 0, // Fare will be calculated in the use case
        polylinePoints: polylineCoordinates,
      );

      return Right(routeDetails);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
