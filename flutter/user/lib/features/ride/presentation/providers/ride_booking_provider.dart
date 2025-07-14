import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user/features/core/network/dio_provider.dart';
import 'package:user/features/ride/domain/entities/ride_request.dart';
import 'package:user/features/ride/domain/repositories/ride_repository.dart';
import 'package:user/features/ride/data/repositories/ride_repository_impl.dart';
import 'package:user/features/ride/data/datasources/ride_remote_datasource.dart';

// Remote datasource provider
final rideRemoteDatasourceProvider = Provider<RideRemoteDatasource>((ref) {
  // You should already have a dioProvider somewhere in your project
  final dio = ref.watch(dioProvider);
  return RideRemoteDatasourceImpl(dio);
});

// RideRepository provider
final rideRepositoryProvider = Provider<RideRepository>((ref) {
  final remote = ref.watch(rideRemoteDatasourceProvider);
  return RideRepositoryImpl(remote);
});

// RideBooking StateNotifier provider
final rideBookingProvider =
    StateNotifierProvider<RideBookingNotifier, AsyncValue<void>>((ref) {
      final repo = ref.watch(rideRepositoryProvider);
      return RideBookingNotifier(repo);
    });

// StateNotifier implementation
class RideBookingNotifier extends StateNotifier<AsyncValue<void>> {
  final RideRepository _repo;

  RideBookingNotifier(this._repo) : super(const AsyncData(null));

  Future<void> bookRide(RideRequest request) async {
    state = const AsyncLoading();
    try {
      await _repo.requestRide(
        request,
      ); // ← match method name in your RideRepositoryImpl
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
