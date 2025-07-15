import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user/features/ride/domain/usecases/calculate_fare_usecase.dart';
import 'package:user/features/ride/domain/usecases/cancel_ride_usecase.dart';
import 'package:user/features/ride/domain/usecases/request_ride_usecase.dart';
import 'package:user/features/ride/presentation/providers/ride_booking_provider.dart';

final calculateFareUseCaseProvider = Provider((ref) => CalculateFareUseCase());

final requestRideUseCaseProvider = Provider((ref) {
  final repository = ref.watch(rideRepositoryProvider);
  return RequestRide(repository);
});

final cancelRideUseCaseProvider = Provider((ref) {
  final repository = ref.watch(rideRepositoryProvider);
  return CancelRide(repository);
});
