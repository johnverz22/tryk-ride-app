import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user/features/ride/domain/usecases/cancel_ride_usecase.dart';
import 'package:user/features/ride/presentation/providers/ride_booking_provider.dart';

final cancelRideUseCaseProvider = Provider((ref) {
  final repository = ref.watch(rideRepositoryProvider);
  return CancelRide(repository);
});

final rideCancellationProvider =
    AsyncNotifierProvider<RideCancellationNotifier, void>(
      RideCancellationNotifier.new,
    );

class RideCancellationNotifier extends AsyncNotifier<void> {
  late final CancelRide _cancelRideUseCase;

  @override
  Future<void> build() async {
    _cancelRideUseCase = ref.read(cancelRideUseCaseProvider);
  }

  Future<void> cancel(int rideId) async {
    state = const AsyncLoading();
    try {
      await _cancelRideUseCase(rideId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
