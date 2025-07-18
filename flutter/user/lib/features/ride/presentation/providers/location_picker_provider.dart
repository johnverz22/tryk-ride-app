import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:user/features/core/errors/failures.dart';
import 'package:user/features/ride/data/datasources/location_remote_datasource_impl.dart';
import 'package:user/features/ride/data/datasources/place_remote_datasource_impl.dart';
import 'package:user/features/ride/data/repositories/location_repository_impl.dart';
import 'package:user/features/ride/data/repositories/place_repository_impl.dart';
import 'package:user/features/ride/domain/entities/location_entity.dart';
import 'package:user/features/ride/domain/entities/place_entity.dart';
import 'package:user/features/ride/domain/usecases/add_saved_location_usecase.dart';
import 'package:user/features/ride/domain/usecases/delete_saved_location_usecase.dart';
import 'package:user/features/ride/domain/usecases/fetch_saved_locations_usecase.dart';
import 'package:user/features/ride/domain/usecases/get_place_details_usecase.dart';
import 'package:user/features/ride/domain/usecases/get_place_name_from_latlng_usecase.dart';
import 'package:user/features/ride/domain/usecases/search_places_usecase.dart';
import 'package:user/features/ride/domain/usecases/update_saved_location_usecase.dart';

// --- (Providers for dependencies and use cases remain the same) ---
final httpClientProvider = Provider((ref) => http.Client());
final secureStorageProvider = Provider((ref) => const FlutterSecureStorage());
final locationRemoteDataSourceProvider = Provider(
  (ref) => LocationRemoteDataSourceImpl(client: ref.watch(httpClientProvider)),
);
final locationRepositoryProvider = Provider(
  (ref) => LocationRepositoryImpl(
    remoteDataSource: ref.watch(locationRemoteDataSourceProvider),
  ),
);
final placeRemoteDataSourceProvider = Provider(
  (ref) => PlaceRemoteDataSourceImpl(client: ref.watch(httpClientProvider)),
);
final placeRepositoryProvider = Provider(
  (ref) => PlaceRepositoryImpl(
    remoteDataSource: ref.watch(placeRemoteDataSourceProvider),
  ),
);
final fetchSavedLocationsUseCaseProvider = Provider(
  (ref) => FetchSavedLocationsUseCase(ref.watch(locationRepositoryProvider)),
);
final addSavedLocationUseCaseProvider = Provider(
  (ref) => AddSavedLocationUseCase(ref.watch(locationRepositoryProvider)),
);
final updateSavedLocationUseCaseProvider = Provider(
  (ref) => UpdateSavedLocationUseCase(ref.watch(locationRepositoryProvider)),
);
final deleteSavedLocationUseCaseProvider = Provider(
  (ref) => DeleteSavedLocationUseCase(ref.watch(locationRepositoryProvider)),
);
final searchPlacesUseCaseProvider = Provider(
  (ref) => SearchPlacesUseCase(ref.watch(placeRepositoryProvider)),
);
final getPlaceDetailsUseCaseProvider = Provider(
  (ref) => GetPlaceDetailsUseCase(ref.watch(placeRepositoryProvider)),
);
final getPlaceNameFromLatLngUseCaseProvider = Provider(
  (ref) => GetPlaceNameFromLatLngUseCase(ref.watch(placeRepositoryProvider)),
);
// ---

// --- State Definition ---
class LocationPickerState {
  final AsyncValue<List<LocationEntity>> favoriteLocations;
  final AsyncValue<List<PlaceSuggestionEntity>> searchResults;
  final LatLng? selectedPoint;
  final String? selectedDescription;
  final bool isSearching;
  final String? errorMessage;
  final bool isAddingOrEditing;
  final bool isLoadingAddress;

  LocationPickerState({
    required this.favoriteLocations,
    required this.searchResults,
    this.selectedPoint,
    this.selectedDescription,
    this.isSearching = false,
    this.errorMessage,
    this.isAddingOrEditing = false,
    this.isLoadingAddress = false,
  });

  LocationPickerState copyWith({
    AsyncValue<List<LocationEntity>>? favoriteLocations,
    AsyncValue<List<PlaceSuggestionEntity>>? searchResults,
    LatLng? selectedPoint,
    String? selectedDescription,
    bool? isSearching,
    String? errorMessage,
    bool? isAddingOrEditing,
    bool? isLoadingAddress,
    Object? selectedDescriptionPlaceholder,
  }) {
    return LocationPickerState(
      favoriteLocations: favoriteLocations ?? this.favoriteLocations,
      searchResults: searchResults ?? this.searchResults,
      selectedPoint: selectedPoint ?? this.selectedPoint,
      selectedDescription: selectedDescriptionPlaceholder is Object
          ? null
          : selectedDescription ?? this.selectedDescription,
      isSearching: isSearching ?? this.isSearching,
      errorMessage: errorMessage,
      isAddingOrEditing: isAddingOrEditing ?? this.isAddingOrEditing,
      isLoadingAddress: isLoadingAddress ?? this.isLoadingAddress,
    );
  }
}

// --- StateNotifier ---
class LocationPickerNotifier extends StateNotifier<LocationPickerState> {
  final FetchSavedLocationsUseCase _fetchSavedLocationsUseCase;
  final AddSavedLocationUseCase _addSavedLocationUseCase;
  final UpdateSavedLocationUseCase _updateSavedLocationUseCase;
  final DeleteSavedLocationUseCase _deleteSavedLocationUseCase;
  final SearchPlacesUseCase _searchPlacesUseCase;
  final GetPlaceDetailsUseCase _getPlaceDetailsUseCase;
  final GetPlaceNameFromLatLngUseCase _getPlaceNameFromLatLngUseCase;
  final FlutterSecureStorage _secureStorage;

  LocationPickerNotifier(
    this._fetchSavedLocationsUseCase,
    this._addSavedLocationUseCase,
    this._updateSavedLocationUseCase,
    this._deleteSavedLocationUseCase,
    this._searchPlacesUseCase,
    this._getPlaceDetailsUseCase,
    this._getPlaceNameFromLatLngUseCase,
    this._secureStorage,
  ) : super(
        LocationPickerState(
          favoriteLocations: const AsyncValue.loading(),
          searchResults: const AsyncValue.data([]),
        ),
      ) {
    _loadFavoriteLocations();
  }

  Future<void> geocodeCameraPosition(LatLng position) async {
    debugPrint('Geocoding position: $position');
    // Step 1: Immediately set state to loading for the new position.
    state = state.copyWith(
      isLoadingAddress: true,
      selectedPoint: position,
      selectedDescriptionPlaceholder: Object(), // Clear out the old address
      errorMessage: null,
    );

    // Step 2: Call the geocoding use case.
    final result = await _getPlaceNameFromLatLngUseCase.call(position);

    // Step 3: Process the result with a safety check.
    result.fold(
      (failure) {
        // SAFETY CHECK: Only update state if the current point is still the one we are geocoding.
        // This prevents a slow response from overwriting a newer selection.
        if (state.selectedPoint == position) {
          debugPrint('Geocoding failed: ${failure.message}');
          state = state.copyWith(
            selectedDescription: 'Unknown location', // Provide a fallback
            isLoadingAddress: false, // IMPORTANT: Stop loading
            errorMessage: failure.message,
          );
        }
      },
      (geocodedAddress) {
        // Same safety check for the success case.
        if (state.selectedPoint == position) {
          debugPrint('Geocoding success: ${geocodedAddress.formattedAddress}');
          state = state.copyWith(
            selectedDescription: geocodedAddress.formattedAddress,
            isLoadingAddress: false, // IMPORTANT: Stop loading
            errorMessage: null,
          );
        }
      },
    );
  }

  Future<String?> _getUserToken() async {
    return await _secureStorage.read(key: 'token');
  }

  Future<void> _loadFavoriteLocations() async {
    debugPrint('LocationPickerNotifier: Loading favorite locations...');
    state = state.copyWith(favoriteLocations: const AsyncValue.loading());
    final token = await _getUserToken();

    if (token == null) {
      state = state.copyWith(
        favoriteLocations: AsyncValue.error(
          const UnauthorizedFailure('Authentication token not found.'),
          StackTrace.current,
        ),
        errorMessage: 'Please log in to view saved locations.',
      );
      return;
    }

    final result = await _fetchSavedLocationsUseCase.call(token);
    result.fold(
      (failure) {
        debugPrint(
          'LocationPickerNotifier: Failed to load favorite locations: ${failure.message}',
        );
        state = state.copyWith(
          favoriteLocations: AsyncValue.error(failure, StackTrace.current),
          errorMessage: failure.message,
        );
      },
      (locations) {
        debugPrint(
          'LocationPickerNotifier: Loaded ${locations.length} favorite locations.',
        );
        state = state.copyWith(
          favoriteLocations: AsyncValue.data(locations),
          errorMessage: null,
        );
      },
    );
  }

  Future<void> addFavoriteLocation(String name, LatLng latLng) async {
    debugPrint(
      'LocationPickerNotifier: Adding favorite location: $name, $latLng',
    );
    state = state.copyWith(isAddingOrEditing: true, errorMessage: null);
    final token = await _getUserToken();

    if (token == null) {
      state = state.copyWith(
        isAddingOrEditing: false,
        errorMessage: 'Authentication token not found.',
      );
      return;
    }

    final result = await _addSavedLocationUseCase.call(token, name, latLng);
    result.fold(
      (failure) {
        debugPrint(
          'LocationPickerNotifier: Failed to add favorite location: ${failure.message}',
        );
        state = state.copyWith(
          isAddingOrEditing: false,
          errorMessage: failure.message,
        );
      },
      (newLocation) {
        debugPrint(
          'LocationPickerNotifier: Added new location: ${newLocation.name}',
        );
        final currentFavorites = state.favoriteLocations.value ?? [];
        state = state.copyWith(
          favoriteLocations: AsyncValue.data([
            ...currentFavorites,
            newLocation,
          ]),
          isAddingOrEditing: false,
          errorMessage: null,
        );
      },
    );
  }

  Future<void> updateFavoriteLocation(
    int id,
    String name,
    LatLng latLng,
  ) async {
    debugPrint(
      'LocationPickerNotifier: Updating favorite location ID: $id, Name: $name, LatLng: $latLng',
    );
    state = state.copyWith(isAddingOrEditing: true, errorMessage: null);
    final token = await _getUserToken();

    if (token == null) {
      state = state.copyWith(
        isAddingOrEditing: false,
        errorMessage: 'Authentication token not found.',
      );
      return;
    }

    final result = await _updateSavedLocationUseCase.call(
      token,
      id,
      name,
      latLng,
    );
    result.fold(
      (failure) {
        debugPrint(
          'LocationPickerNotifier: Failed to update favorite location: ${failure.message}',
        );
        state = state.copyWith(
          isAddingOrEditing: false,
          errorMessage: failure.message,
        );
      },
      (updatedLocation) {
        debugPrint(
          'LocationPickerNotifier: Updated location: ${updatedLocation.name}',
        );
        final currentFavorites = state.favoriteLocations.value ?? [];
        final updatedList = currentFavorites
            .map((loc) => loc.id == updatedLocation.id ? updatedLocation : loc)
            .toList();
        state = state.copyWith(
          favoriteLocations: AsyncValue.data(updatedList),
          isAddingOrEditing: false,
          errorMessage: null,
        );
      },
    );
  }

  Future<void> deleteFavoriteLocation(int id) async {
    debugPrint('LocationPickerNotifier: Deleting favorite location ID: $id');
    state = state.copyWith(
      errorMessage: null,
    ); // Don't set isAddingOrEditing for delete
    final token = await _getUserToken();

    if (token == null) {
      state = state.copyWith(errorMessage: 'Authentication token not found.');
      return;
    }

    final result = await _deleteSavedLocationUseCase.call(token, id);
    result.fold(
      (failure) {
        debugPrint(
          'LocationPickerNotifier: Failed to delete favorite location: ${failure.message}',
        );
        state = state.copyWith(errorMessage: failure.message);
      },
      (_) {
        debugPrint('LocationPickerNotifier: Deleted location ID: $id');
        final currentFavorites = state.favoriteLocations.value ?? [];
        final updatedList = currentFavorites
            .where((loc) => loc.id != id)
            .toList();
        state = state.copyWith(
          favoriteLocations: AsyncValue.data(updatedList),
          errorMessage: null,
        );
      },
    );
  }

  Future<void> searchPlaces(String query) async {
    debugPrint('LocationPickerNotifier: Searching places for query: $query');
    if (query.isEmpty) {
      state = state.copyWith(
        searchResults: const AsyncValue.data([]),
        isSearching: false,
        errorMessage: null,
      );
      return;
    }

    state = state.copyWith(
      searchResults: const AsyncValue.loading(),
      isSearching: true,
      errorMessage: null,
    );
    final result = await _searchPlacesUseCase.call(query);
    result.fold(
      (failure) {
        debugPrint(
          'LocationPickerNotifier: Place search failed: ${failure.message}',
        );
        state = state.copyWith(
          searchResults: AsyncValue.error(failure, StackTrace.current),
          errorMessage: failure.message,
          isSearching: false,
        );
      },
      (suggestions) {
        debugPrint(
          'LocationPickerNotifier: Found ${suggestions.length} place suggestions.',
        );
        state = state.copyWith(
          searchResults: AsyncValue.data(suggestions),
          isSearching: false,
          errorMessage: null,
        );
      },
    );
  }

  Future<LatLng?> selectPlace(String placeId, String description) async {
    debugPrint(
      'LocationPickerNotifier: Selecting place: $placeId, $description',
    );
    // When a place is selected from search, we assume the description is correct
    // for immediate display, then fetch precise details (LatLng).
    // Set isLoadingAddress to true as we fetch details.
    state = state.copyWith(
      selectedDescription: description,
      searchResults: const AsyncValue.data([]),
      isSearching: false,
      errorMessage: null,
      isLoadingAddress: true, // Start loading for details
    );

    LatLng?
    returnedLatLng; // Declare a variable to store the LatLng for returning

    final result = await _getPlaceDetailsUseCase.call(placeId);
    result.fold(
      (failure) {
        debugPrint(
          'LocationPickerNotifier: Failed to get place details: ${failure.message}',
        );
        state = state.copyWith(
          selectedPoint: null,
          selectedDescription: 'Failed to load details', // Indicate failure
          errorMessage: failure.message,
          isLoadingAddress: false, // Stop loading
        );
        returnedLatLng = null;
      },
      (placeDetails) {
        debugPrint(
          'LocationPickerNotifier: Place details received: ${placeDetails.name}, ${placeDetails.latLng}',
        );
        state = state.copyWith(
          selectedPoint: placeDetails.latLng,
          selectedDescription:
              placeDetails.formattedAddress ?? placeDetails.name,
          errorMessage: null,
          isLoadingAddress: false, // Stop loading
        );
        returnedLatLng = placeDetails.latLng;
      },
    );

    return returnedLatLng;
  }

  void setLoadingState() {
    // Check if we're already in a loading state to avoid unnecessary rebuilds.
    if (!state.isLoadingAddress) {
      state = state.copyWith(
        isLoadingAddress: true,
        // Clear the previous description so the UI shows "Loading address..."
        selectedDescriptionPlaceholder: Object(),
      );
    }
  }

  Future<void> getPlaceNameFromLatLng(LatLng latLng) async {
    debugPrint(
      'LocationPickerNotifier: Getting place name from LatLng: $latLng',
    );

    // Set loading state and clear previous description to show "Loading..."
    state = state.copyWith(
      isLoadingAddress: true,
      selectedDescription: 'Loading address...', // Provide immediate feedback
      errorMessage: null,
    );

    final result = await _getPlaceNameFromLatLngUseCase.call(latLng);

    result.fold(
      (failure) {
        debugPrint(
          'LocationPickerNotifier: Failed to get place name from LatLng: ${failure.message}',
        );
        state = state.copyWith(
          selectedDescription: 'Unknown location', // Fallback text
          errorMessage: failure.message,
          isLoadingAddress: false, // Turn off loading
        );
      },
      (geocodedAddress) {
        debugPrint(
          'LocationPickerNotifier: Geocoded address: ${geocodedAddress.formattedAddress}',
        );
        state = state.copyWith(
          selectedDescription: geocodedAddress.formattedAddress,
          errorMessage: null,
          isLoadingAddress: false, // Turn off loading
        );
      },
    );
  }

  void setSelectedPoint(LatLng point) {
    debugPrint('LocationPickerNotifier: setSelectedPoint: $point');
    // DO NOT set isLoadingAddress to true here.
    // The loading state should be managed by the method that actually does the loading (getPlaceNameFromLatLng).
    state = state.copyWith(
      selectedPoint: point,
      // Clear the description so the UI knows it's stale and needs updating.
      selectedDescription: null,
      errorMessage: null,
    );
  }

  void setSelectedPointAndDescription(LatLng? point, String? description) {
    debugPrint('Setting point and description directly: $point, $description');
    state = state.copyWith(
      selectedPoint: point,
      selectedDescription: description,
      isLoadingAddress: false, // No loading is needed
      errorMessage: null,
    );
  }

  void clearSearch() {
    debugPrint('Clearing search results.');
    state = state.copyWith(
      searchResults: const AsyncValue.data([]),
      isSearching: false,
      errorMessage: null,
    );
  }
}

final locationPickerProvider =
    StateNotifierProvider<LocationPickerNotifier, LocationPickerState>((ref) {
      return LocationPickerNotifier(
        ref.watch(fetchSavedLocationsUseCaseProvider),
        ref.watch(addSavedLocationUseCaseProvider),
        ref.watch(updateSavedLocationUseCaseProvider),
        ref.watch(deleteSavedLocationUseCaseProvider),
        ref.watch(searchPlacesUseCaseProvider),
        ref.watch(getPlaceDetailsUseCaseProvider),
        ref.watch(getPlaceNameFromLatLngUseCaseProvider),
        ref.watch(secureStorageProvider),
      );
    });
final geocodedAddressProvider = FutureProvider.autoDispose.family<String, LatLng>(
  (ref, latLng) async {
    final getPlaceNameUseCase = ref.watch(
      getPlaceNameFromLatLngUseCaseProvider,
    );
    final result = await getPlaceNameUseCase.call(latLng);

    return result.fold(
      (failure) =>
          'Could not determine address', // Return a fallback message on failure
      (geocodedAddress) => geocodedAddress
          .formattedAddress, // Return the address string on success
    );
  },
);
