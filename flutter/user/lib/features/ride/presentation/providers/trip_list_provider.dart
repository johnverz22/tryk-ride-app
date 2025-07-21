// user/features/ride/presentation/providers/trip_list_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart'; // Import for debugPrint

import '../../data/datasources/trip_remote_datasource_impl.dart';
import '../../data/repositories/trip_repository_impl.dart';
import '../../domain/entities/trip_entity.dart';
import '../../domain/usecases/fetch_user_trips_usecase.dart';
import '../../../core/errors/failures.dart'; // Import your failures

// Providers for dependencies
final httpClientProvider = Provider((ref) => http.Client());
final secureStorageProvider = Provider((ref) => const FlutterSecureStorage());

final tripRemoteDataSourceProvider = Provider((ref) {
  return TripRemoteDataSourceImpl(client: ref.watch(httpClientProvider));
});

final tripRepositoryProvider = Provider((ref) {
  return TripRepositoryImpl(
    remoteDataSource: ref.watch(tripRemoteDataSourceProvider),
  );
});

final fetchUserTripsUseCaseProvider = Provider((ref) {
  return FetchUserTripsUseCase(repository: ref.watch(tripRepositoryProvider));
});

// State for the trip list
class TripListState {
  final AsyncValue<List<TripEntity>> trips;
  final int currentPage;
  final bool hasMore;
  final String? errorMessage; // For specific error messages

  TripListState({
    required this.trips,
    this.currentPage = 1,
    this.hasMore = true,
    this.errorMessage,
  });

  TripListState copyWith({
    AsyncValue<List<TripEntity>>? trips,
    int? currentPage,
    bool? hasMore,
    String? errorMessage,
  }) {
    return TripListState(
      trips: trips ?? this.trips,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage, // Explicitly set to null if not provided
    );
  }
}

// StateNotifier for managing the trip list logic
class TripListNotifier extends StateNotifier<TripListState> {
  final FetchUserTripsUseCase _fetchUserTripsUseCase;
  final FlutterSecureStorage _secureStorage;

  TripListNotifier(this._fetchUserTripsUseCase, this._secureStorage)
    : super(TripListState(trips: const AsyncValue.data([]))) {
    debugPrint('TripListNotifier: Constructor called. Initiating loadTrips().');
    loadTrips(); // Initial load
  }

  Future<String?> _getUserToken() async {
    debugPrint(
      'TripListNotifier: Attempting to get user token from secure storage.',
    );
    final token = await _secureStorage.read(key: 'token');
    debugPrint(
      'TripListNotifier: Token retrieved: ${token != null ? 'YES' : 'NO'}',
    );
    return token;
  }

  Future<void> loadTrips({
    bool isRefresh = false,
    bool loadMore = false,
  }) async {
    debugPrint(
      'TripListNotifier: loadTrips called. isRefresh: $isRefresh, loadMore: $loadMore',
    );

    if (loadMore && !state.hasMore) {
      debugPrint('TripListNotifier: No more data to load.');
      return;
    }

    // Prevent duplicate fetches if already loading (unless it's a refresh)
    if (state.trips.isLoading && !isRefresh) {
      debugPrint('TripListNotifier: Already loading, returning early.');
      return;
    }

    // Determine the new page number
    final int nextPage = loadMore ? state.currentPage + 1 : 1;
    debugPrint('TripListNotifier: Determining next page: $nextPage');

    // Set loading state
    if (isRefresh) {
      state = state.copyWith(
        trips: const AsyncValue.loading(),
        currentPage: 1, // Reset to 1 on refresh
      );
    } else if (loadMore) {
      // This state is for the API call, UI state is handled by hasMore flag
    } else {
      // Initial load
      state = state.copyWith(trips: const AsyncValue.loading());
    }

    final token = await _getUserToken();
    if (token == null) {
      state = state.copyWith(
        trips: AsyncValue.error(
          const UnauthorizedFailure('Authentication token not found.'),
          StackTrace.current,
        ),
        errorMessage: 'Please log in to view your trips.',
      );
      return;
    }

    debugPrint(
      'TripListNotifier: Calling FetchUserTripsUseCase for page: $nextPage',
    );
    // Use the calculated nextPage, not the one from the state before the call
    final result = await _fetchUserTripsUseCase.call(token, page: nextPage);

    result.fold(
      (failure) {
        debugPrint(
          'TripListNotifier: Fetch failed with error: ${failure.message}',
        );
        state = state.copyWith(
          trips: AsyncValue.error(failure, StackTrace.current),
          errorMessage: failure.message,
        );
      },
      (newTrips) {
        debugPrint(
          'TripListNotifier: Fetch successful. Received ${newTrips.length} new trips.',
        );

        // --- START: CORRECTED LOGIC ---

        // FIX 1: Robustly get the previous list of trips.
        // On refresh, start with an empty list. Otherwise, use the existing list,
        // defaulting to an empty list `[]` if it's somehow null (e.g., after an error).
        final previousTrips = isRefresh
            ? <TripEntity>[]
            : state.trips.value ?? [];
        final combinedTrips = previousTrips + newTrips;

        // Define your page size as a constant
        const int pageSize = 10;

        // FIX 2: Correct 'hasMore' logic.
        // We have more items to fetch if the API returned a full page.
        final bool hasMore = newTrips.length == pageSize;

        state = state.copyWith(
          trips: AsyncValue.data(combinedTrips),
          // FIX 3: Explicitly update the current page number in the state.
          currentPage: nextPage,
          hasMore: hasMore,
          errorMessage: null,
        );

        debugPrint(
          'TripListNotifier: State updated with ${combinedTrips.length} total trips.',
        );
      },
    );
  }
}

final tripListProvider = StateNotifierProvider<TripListNotifier, TripListState>(
  (ref) {
    return TripListNotifier(
      ref.watch(fetchUserTripsUseCaseProvider),
      ref.watch(secureStorageProvider),
    );
  },
);
