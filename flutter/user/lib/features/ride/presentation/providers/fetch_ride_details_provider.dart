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
    // No rideId yet — wait for manual trigger via fetch()
    return null;
  }

  Future<void> fetch(int rideId) async {
    state = const AsyncLoading();
    try {
      _useCase = ref.read(fetchRideDetailsUseCaseProvider);
      final rideDetails = await _useCase(rideId);
      state = AsyncData(rideDetails);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
