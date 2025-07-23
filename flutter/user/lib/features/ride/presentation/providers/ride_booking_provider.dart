import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:user/features/core/network/dio_provider.dart';
import 'package:user/features/ride/data/datasources/ride_remote_datasource.dart';
import 'package:user/features/ride/data/datasources/ride_remote_datasource_impl.dart';
import 'package:user/features/ride/data/repositories/ride_repository_impl.dart';
import 'package:user/features/ride/data/services/ride_socket_service.dart';
import 'package:user/features/ride/domain/entities/driver_location.dart';
import 'package:user/features/ride/domain/entities/ride.dart';
import 'package:user/features/ride/domain/entities/route_details.dart';
import 'package:user/features/ride/domain/repositories/ride_repository.dart';
import 'package:user/features/ride/domain/usecases/get_route_details.dart';
import 'package:user/features/ride/domain/usecases/request_ride_usecase.dart';
import 'package:user/features/ride/domain/usecases/stream_driver_location_usecase.dart';

// --- STATE DEFINITION ---

// Enum to manage the screen's current UI state
enum ScreenState { booking, pickingPickup, pickingDestination }

class RideBookingState extends Equatable {
  // UI State
  final ScreenState screenState;

  // Map State
  final CameraPosition? initialCameraPosition;
  final Set<Marker> markers;
  final Set<Polyline> polylines;

  // Ride Booking State
  final LatLng? fromLocation;
  final LatLng? toLocation;
  final String fromAddress;
  final String toAddress;
  final String selectedPaymentMethod;
  final RouteDetails? routeDetails;

  // Loading & Error State
  final bool isRouteLoading;
  final bool isRideRequestLoading;
  final String? errorMessage;

  const RideBookingState({
    this.screenState = ScreenState.booking,
    this.initialCameraPosition,
    this.markers = const {},
    this.polylines = const {},
    this.fromLocation,
    this.toLocation,
    this.fromAddress = "Select pickup location",
    this.toAddress = "Where to?",
    this.selectedPaymentMethod = 'Cash',
    this.routeDetails,
    this.isRouteLoading = false,
    this.isRideRequestLoading = false,
    this.errorMessage,
  });

  // copyWith allows for easy, immutable state updates
  RideBookingState copyWith({
    ScreenState? screenState,
    CameraPosition? initialCameraPosition,
    Set<Marker>? markers,
    Set<Polyline>? polylines,
    LatLng? fromLocation,
    LatLng? toLocation,
    String? fromAddress,
    String? toAddress,
    String? selectedPaymentMethod,
    RouteDetails? routeDetails,
    bool? isRouteLoading,
    bool? isRideRequestLoading,
    String? errorMessage,
    bool clearRoute = false,
  }) {
    return RideBookingState(
      screenState: screenState ?? this.screenState,
      initialCameraPosition:
          initialCameraPosition ?? this.initialCameraPosition,
      markers: markers ?? this.markers,
      polylines: polylines ?? this.polylines,
      fromLocation: fromLocation ?? this.fromLocation,
      toLocation: toLocation ?? this.toLocation,
      fromAddress: fromAddress ?? this.fromAddress,
      toAddress: toAddress ?? this.toAddress,
      selectedPaymentMethod:
          selectedPaymentMethod ?? this.selectedPaymentMethod,
      routeDetails: clearRoute ? null : routeDetails ?? this.routeDetails,
      isRouteLoading: isRouteLoading ?? this.isRouteLoading,
      isRideRequestLoading: isRideRequestLoading ?? this.isRideRequestLoading,
      errorMessage:
          errorMessage, // Don't preserve error message on state change
    );
  }

  @override
  List<Object?> get props => [
    screenState,
    initialCameraPosition,
    markers,
    polylines,
    fromLocation,
    toLocation,
    fromAddress,
    toAddress,
    selectedPaymentMethod,
    routeDetails,
    isRouteLoading,
    isRideRequestLoading,
    errorMessage,
  ];
}

// --- INFRASTRUCTURE / SERVICE PROVIDERS ---

final polylinePointsProvider = Provider<PolylinePoints>(
  (ref) => PolylinePoints(),
);
final rideSocketServiceProvider = Provider(
  (ref) => RideSocketService(ref.read(dioProvider)),
);

// --- DATA LAYER PROVIDERS ---

final rideRemoteDatasourceProvider = Provider<RideRemoteDatasource>((ref) {
  return RideRemoteDatasourceImpl(
    ref.watch(dioProvider),
    ref.watch(rideSocketServiceProvider),
    ref.watch(polylinePointsProvider),
  );
});

final rideRepositoryProvider = Provider<RideRepository>((ref) {
  return RideRepositoryImpl(ref.watch(rideRemoteDatasourceProvider));
});

// --- DOMAIN LAYER (USE CASE) PROVIDERS ---

final getRouteDetailsUseCaseProvider = Provider<GetRouteDetails>(
  (ref) => GetRouteDetails(ref.watch(rideRepositoryProvider)),
);

final requestRideUseCaseProvider = Provider<RequestRide>((ref) {
  final repository = ref.read(rideRepositoryProvider);
  return RequestRide(repository);
});

final streamDriverLocationUseCaseProvider = Provider<StreamDriverLocation>((
  ref,
) {
  return StreamDriverLocation(ref.read(rideRepositoryProvider));
});

// --- PRESENTATION LAYER (NOTIFIER & PROVIDER) ---

class RideBookingNotifier extends StateNotifier<RideBookingState> {
  final GetRouteDetails _getRouteDetailsUseCase;
  // THE FIX: Add the missing dependency
  final RequestRide _requestRideUseCase;

  // THE FIX: Update the constructor to accept the new dependency
  RideBookingNotifier({
    required GetRouteDetails getRouteDetailsUseCase,
    required RequestRide requestRideUseCase,
  }) : _getRouteDetailsUseCase = getRouteDetailsUseCase,
       _requestRideUseCase = requestRideUseCase,
       super(const RideBookingState());

  // === PUBLIC METHODS (Called by the UI) ===

  void setInitialLocation(LatLng location, String address) {
    if (state.fromLocation == location) return;
    state = state.copyWith(
      fromLocation: location,
      fromAddress: address,
      initialCameraPosition: CameraPosition(target: location, zoom: 16.0),
    );
  }

  void enterLocationPickingMode(ScreenState targetState) {
    state = state.copyWith(
      screenState: targetState,
      polylines: {},
      markers: {},
      clearRoute: true,
    );
  }

  void exitLocationPickingMode() {
    state = state.copyWith(screenState: ScreenState.booking);
    if (state.fromLocation != null && state.toLocation != null) {
      fetchAndDrawRoute();
    }
  }

  void confirmPickedLocation(LatLng location, String address) {
    if (state.screenState == ScreenState.pickingPickup) {
      state = state.copyWith(fromLocation: location, fromAddress: address);
    } else {
      state = state.copyWith(toLocation: location, toAddress: address);
    }
    exitLocationPickingMode();
  }

  Future<void> fetchAndDrawRoute() async {
    if (state.fromLocation == null || state.toLocation == null) return;

    state = state.copyWith(isRouteLoading: true);
    final result = await _getRouteDetailsUseCase(
      state.fromLocation!,
      state.toLocation!,
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          isRouteLoading: false,
          errorMessage: failure.message,
        );
      },
      (route) {
        final newMarkers = {
          Marker(
            markerId: const MarkerId('pickup'),
            position: state.fromLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
          Marker(
            markerId: const MarkerId('dropoff'),
            position: state.toLocation!,
          ),
        };
        final newPolylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: route.polylinePoints,
            color: Colors.deepPurple,
            width: 5,
          ),
        };
        state = state.copyWith(
          isRouteLoading: false,
          routeDetails: route,
          markers: newMarkers,
          polylines: newPolylines,
        );
      },
    );
  }

  // THE FIX: Add the missing handleRideRequest method
  Future<void> handleRideRequest({
    required void Function(String message) onFailure,
    required void Function(int rideId) onSuccess,
  }) async {
    if (state.fromLocation == null ||
        state.toLocation == null ||
        state.routeDetails == null)
      return;

    state = state.copyWith(isRideRequestLoading: true);

    final rideRequest = Ride(
      pickupAddress: state.fromAddress,
      pickupLatitude: state.fromLocation!.latitude,
      pickupLongitude: state.fromLocation!.longitude,
      dropoffAddress: state.toAddress,
      dropoffLatitude: state.toLocation!.latitude,
      dropoffLongitude: state.toLocation!.longitude,
      requestedAt: DateTime.now(),
      distanceKm: state.routeDetails!.distanceInKm,
      durationMinutes: state.routeDetails!.durationInMinutes,
      fareAmount: state.routeDetails!.fare,
      paymentMethod: state.selectedPaymentMethod,
      searchRadiusKm: 10,
    );

    final result = await _requestRideUseCase(rideRequest);
    state = state.copyWith(isRideRequestLoading: false);

    result.fold(
      (failure) => onFailure('Ride Request Failed: ${failure.message}'),
      (rideId) => onSuccess(rideId),
    );
  }
}

// THE FIX: Update the provider to pass all required use cases to the notifier
final rideBookingProvider =
    StateNotifierProvider<RideBookingNotifier, RideBookingState>((ref) {
      return RideBookingNotifier(
        getRouteDetailsUseCase: ref.watch(getRouteDetailsUseCaseProvider),
        requestRideUseCase: ref.watch(requestRideUseCaseProvider),
      );
    });

// --- STREAM PROVIDER (for other features) ---

final driverLocationStreamProvider = StreamProvider.autoDispose
    .family<DriverLocationEntity, int>((ref, rideId) {
      final streamDriverLocation = ref.watch(
        streamDriverLocationUseCaseProvider,
      );
      final stream = streamDriverLocation(rideId);

      return stream.map((either) {
        return either.fold(
          (failure) => throw failure,
          (driverLocation) => driverLocation,
        );
      });
    });
