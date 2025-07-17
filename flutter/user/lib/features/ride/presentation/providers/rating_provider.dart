import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:user/features/ride/domain/entities/rating.dart';
import 'package:user/features/ride/data/repositories/rating_repository_impl.dart';
import 'package:user/features/ride/domain/repositories/rating_repository.dart';
import 'package:user/features/ride/domain/usecases/submit_ride_rating_usecase.dart';
import 'package:user/core/services/auth_service.dart'; // Make sure this is imported

// Provider for http client (can be globally accessible)
final httpClientProvider = Provider((ref) => http.Client());

// Provider for AuthService
final authServiceProvider = Provider(
  (ref) => AuthService(),
); // Assuming AuthService is a simple class

// Provider for RatingRepository
final ratingRepositoryProvider = Provider<RatingRepository>((ref) {
  return RatingRepositoryImpl(
    client: ref.read(httpClientProvider),
    authService: ref.read(authServiceProvider),
  );
});

// Provider for SubmitRideRatingUseCase
final submitRideRatingUseCaseProvider = Provider<SubmitRideRatingUseCase>((
  ref,
) {
  return SubmitRideRatingUseCase(ref.read(ratingRepositoryProvider));
});

// StateNotifierProvider for handling rating submission state
final rideRatingSubmissionProvider =
    StateNotifierProvider<RideRatingSubmissionNotifier, AsyncValue<void>>((
      ref,
    ) {
      return RideRatingSubmissionNotifier(
        ref.read(submitRideRatingUseCaseProvider),
      );
    });

class RideRatingSubmissionNotifier extends StateNotifier<AsyncValue<void>> {
  final SubmitRideRatingUseCase _submitRideRatingUseCase;

  RideRatingSubmissionNotifier(this._submitRideRatingUseCase)
    : super(const AsyncValue.data(null));

  Future<void> submitRating(int rideId, Rating rating) async {
    state = const AsyncValue.loading();
    final result = await _submitRideRatingUseCase(rideId, rating);
    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (_) => state = const AsyncValue.data(null),
    );
  }
}
