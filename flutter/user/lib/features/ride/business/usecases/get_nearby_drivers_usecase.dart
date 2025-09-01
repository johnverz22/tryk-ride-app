import 'package:dartz/dartz.dart';
import '../entities/driver_entity.dart';
import '../entities/ride_entity.dart';
import '../repositories/ride_repository.dart';
import '../../../../core/errors/failures.dart';

class GetNearbyDriversParams {
  final double latitude;
  final double longitude;
  final double radiusKm;
  final RideType? rideType;

  GetNearbyDriversParams({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 5.0,
    this.rideType,
  });
}

class GetNearbyDriversUseCase {
  final RideRepository repository;

  GetNearbyDriversUseCase(this.repository);

  Future<Either<Failure, List<DriverEntity>>> call(GetNearbyDriversParams params) async {
    return await repository.getNearbyDrivers(
      latitude: params.latitude,
      longitude: params.longitude,
      radiusKm: params.radiusKm,
      rideType: params.rideType,
    );
  }
}