import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user/features/core/network/dio_provider.dart';
import 'package:user/features/ride/data/datasources/ride_remote_datasource.dart';
import 'package:user/features/ride/data/datasources/ride_remote_datasource_impl.dart';
import 'package:user/features/ride/data/repositories/ride_repository_impl.dart';
import 'package:user/features/ride/data/services/ride_socket_service.dart';
import 'package:user/features/ride/domain/entities/driver_location.dart';
import 'package:user/features/ride/domain/repositories/ride_repository.dart';
import 'package:user/features/ride/domain/usecases/get_route_details.dart';
import 'package:user/features/ride/domain/usecases/request_ride_usecase.dart';
import 'package:user/features/ride/domain/usecases/stream_driver_location_usecase.dart';

// --- INFRASTRUCTURE / SERVICE PROVIDERS ---

/// Provides an instance of [PolylinePoints] for route calculations.
final polylinePointsProvider = Provider<PolylinePoints>(
  (ref) => PolylinePoints(),
);

/// Provides the WebSocket service for real-time ride communication.
final rideSocketServiceProvider = Provider<RideSocketService>((ref) {
  // Uses `ref.read` as the Dio instance is not expected to change during the socket's lifecycle.
  return RideSocketService(ref.read(dioProvider));
});

// --- DATA LAYER PROVIDERS ---

/// Provides the concrete implementation of the remote data source.
final rideRemoteDatasourceProvider = Provider<RideRemoteDatasource>((ref) {
  // Uses `ref.watch` to rebuild if dependencies change.
  final dio = ref.watch(dioProvider);
  final rideSocketService = ref.watch(rideSocketServiceProvider);
  final polylinePoints = ref.watch(polylinePointsProvider);

  return RideRemoteDatasourceImpl(dio, rideSocketService, polylinePoints);
});

/// Provides the concrete implementation of the ride repository.
final rideRepositoryProvider = Provider<RideRepository>((ref) {
  final remoteDatasource = ref.watch(rideRemoteDatasourceProvider);
  return RideRepositoryImpl(remoteDatasource);
});

// --- DOMAIN LAYER (USE CASE) PROVIDERS ---

/// Use case for requesting a new ride.
final requestRideUseCaseProvider = Provider<RequestRide>((ref) {
  final repository = ref.watch(rideRepositoryProvider);
  return RequestRide(repository);
});

/// Use case for calculating route details (polylines, distance, etc.).
final getRouteDetailsUseCaseProvider = Provider<GetRouteDetails>(
  (ref) => GetRouteDetails(ref.watch(rideRepositoryProvider)),
);

/// Use case for streaming the driver's live location.
final streamDriverLocationUseCaseProvider = Provider<StreamDriverLocation>((
  ref,
) {
  return StreamDriverLocation(ref.read(rideRepositoryProvider));
});

// --- PRESENTATION LAYER (STREAM) PROVIDER ---

/// Provides a stream of the driver's location for a given ride ID.
/// The stream automatically handles successes and failures from the use case.
final driverLocationStreamProvider = StreamProvider.autoDispose
    .family<DriverLocationEntity, int>((ref, rideId) {
      final streamDriverLocation = ref.watch(
        streamDriverLocationUseCaseProvider,
      );
      final stream = streamDriverLocation(rideId);

      // The stream from the use case returns an Either<Failure, DriverLocation>.
      // We map over it to either provide the data or throw an error to the UI.
      return stream.map((eitherResult) {
        return eitherResult.fold(
          (failure) =>
              throw failure, // Propagates the error to AsyncValue.error
          (driverLocation) =>
              driverLocation, // Provides the data to AsyncValue.data
        );
      });
    });
