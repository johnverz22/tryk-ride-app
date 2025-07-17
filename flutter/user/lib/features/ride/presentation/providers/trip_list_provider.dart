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

    // If loading more and no more data, just return.
    if (loadMore && !state.hasMore) {
      debugPrint('TripListNotifier: No more data to load.');
      return;
    }

    if (state.trips.isLoading &&
        state.trips.value != null &&
        !isRefresh &&
        !loadMore) {
      debugPrint('TripListNotifier: Already loading, returning early.');
      return;
    }

    // Determine the new page number
    final int nextPage = loadMore ? state.currentPage + 1 : 1;
    debugPrint('TripListNotifier: Determining next page: $nextPage');

    // Set loading state based on the type of load
    if (isRefresh) {
      debugPrint('TripListNotifier: Setting state to refresh loading.');
      state = state.copyWith(
        trips: const AsyncValue.loading(),
        currentPage: 1,
        hasMore: true,
        errorMessage: null,
      );
    } else if (loadMore) {
      debugPrint('TripListNotifier: Setting state to load more loading.');
      state = state.copyWith(
        trips: AsyncValue.data(state.trips.value ?? []),
        currentPage: nextPage,
        errorMessage: null,
      );
    } else {
      debugPrint('TripListNotifier: Setting state to initial loading.');
      state = state.copyWith(
        trips: const AsyncValue.loading(),
        currentPage: 1,
        hasMore: true,
        errorMessage: null,
      );
    }

    final token = await _getUserToken();
    if (token == null) {
      debugPrint(
        'TripListNotifier: Token is null, setting UnauthorizedFailure.',
      );
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
      'TripListNotifier: Calling FetchUserTripsUseCase for page: ${state.currentPage}',
    );
    final result = await _fetchUserTripsUseCase.call(
      token,
      page: state.currentPage,
    );

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
        // Combine existing trips with newly fetched ones
        final currentTrips = (isRefresh || state.trips.value == null)
            ? <TripEntity>[]
            : state.trips.value!;
        final combinedTrips = [...currentTrips, ...newTrips];

        state = state.copyWith(
          trips: AsyncValue.data(combinedTrips),
          hasMore: newTrips.length == 10,
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
