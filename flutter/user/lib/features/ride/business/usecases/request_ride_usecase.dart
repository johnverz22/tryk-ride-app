import 'package:dartz/dartz.dart';
import '../entities/ride_entity.dart';
import '../repositories/ride_repository.dart';
import '../../../../core/errors/failures.dart';

class RequestRideParams {
  final RideType rideType;
  final String pickupAddress;
  final double pickupLatitude;
  final double pickupLongitude;
  final String dropoffAddress;
  final double dropoffLatitude;
  final double dropoffLongitude;
  final String? paymentMethod;

  RequestRideParams({
    required this.rideType,
    required this.pickupAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.dropoffAddress,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    this.paymentMethod,
  });
}

class RequestRideUseCase {
  final RideRepository repository;

  RequestRideUseCase(this.repository);

  Future<Either<Failure, RideEntity>> call(RequestRideParams params) async {
    return await repository.requestRide(
      rideType: params.rideType,
      pickupAddress: params.pickupAddress,
      pickupLatitude: params.pickupLatitude,
      pickupLongitude: params.pickupLongitude,
      dropoffAddress: params.dropoffAddress,
      dropoffLatitude: params.dropoffLatitude,
      dropoffLongitude: params.dropoffLongitude,
      paymentMethod: params.paymentMethod,
    );
  }
}