import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user/features/ride/domain/entities/ride_details.dart';
import 'package:user/features/ride/domain/usecases/fetch_ride_details_usecase.dart';
import 'package:user/features/ride/presentation/providers/ride_booking_provider.dart';

final fetchRideDetailsUseCaseProvider = Provider<FetchRideDetails>((ref) {
  final repository = ref.watch(rideRepositoryProvider);
  return FetchRideDetails(repository);
});

final fetchRideDetailsProvider =
    AsyncNotifierProvider.autoDispose<FetchRideDetailsNotifier, RideDetails?>(
      FetchRideDetailsNotifier.new,
    );

class FetchRideDetailsNotifier extends AutoDisposeAsyncNotifier<RideDetails?> {
  late final FetchRideDetails _useCase;

  @override
  Future<RideDetails?> build() async {
    // Initialize the use case here, as `ref` is available
    _useCase = ref.read(fetchRideDetailsUseCaseProvider);
    // No rideId yet — wait for manual trigger via fetch()
    return null;
  }

  Future<void> fetch(int rideId) async {
    state = const AsyncLoading();
    final result = await _useCase(
      rideId,
    ); // This returns Either<Failure, RideDetails>

    state = result.fold(
      (failure) {
        // On failure, update the state to AsyncError with the failure message
        return AsyncError(failure.message, StackTrace.current);
      },
      (rideDetails) {
        // On success, update the state to AsyncData with the RideDetails
        return AsyncData(rideDetails);
      },
    );
  }
}
