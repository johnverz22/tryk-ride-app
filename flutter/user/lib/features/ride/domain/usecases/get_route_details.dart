import 'package:dartz/dartz.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:user/features/core/errors/failures.dart';
import 'package:user/features/ride/domain/entities/route_details.dart';
import 'package:user/features/ride/domain/repositories/ride_repository.dart';

class GetRouteDetails {
  final RideRepository repository;

  // Constants for fare calculation now live here
  static const double _baseFare = 5.0;
  static const double _perKmRate = 2.0;

  GetRouteDetails(this.repository);

  Future<Either<Failure, RouteDetails>> call(LatLng from, LatLng to) async {
    final routeResult = await repository.getRouteDetails(from, to);

    // The business rule for calculating fare is now isolated here
    return routeResult.map((route) {
      final estimatedFare = _baseFare + (_perKmRate * route.distanceInKm);
      return RouteDetails(
        distanceInKm: route.distanceInKm,
        durationInMinutes: route.durationInMinutes,
        fare: estimatedFare,
        polylinePoints: route.polylinePoints,
      );
    });
  }
}
