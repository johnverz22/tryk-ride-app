import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user/features/core/network/dio_provider.dart';
import 'package:user/features/ride/data/services/ride_socket_service.dart';
import 'package:user/features/ride/data/datasources/ride_remote_datasource.dart';
import 'package:user/features/ride/data/datasources/ride_remote_datasource_impl.dart';
import 'package:user/features/ride/domain/entities/driver_location.dart';
import 'package:user/features/ride/domain/repositories/ride_repository.dart';
import 'package:user/features/ride/data/repositories/ride_repository_impl.dart';
import 'package:user/features/ride/domain/usecases/stream_driver_location_usecase.dart';

final rideSocketServiceProvider = Provider((ref) {
  return RideSocketService(ref.read(dioProvider));
});

final rideRemoteDatasourceProvider = Provider<RideRemoteDatasource>((ref) {
  final dio = ref.watch(dioProvider);
  final rideSocketService = ref.watch(rideSocketServiceProvider);
  return RideRemoteDatasourceImpl(dio, rideSocketService);
});

final rideRepositoryProvider = Provider<RideRepository>((ref) {
  return RideRepositoryImpl(ref.read(rideRemoteDatasourceProvider));
});

final streamDriverLocationUseCaseProvider = Provider<StreamDriverLocation>((
  ref,
) {
  return StreamDriverLocation(ref.read(rideRepositoryProvider));
});

final driverLocationStreamProvider = StreamProvider.autoDispose
    .family<AsyncValue<DriverLocationEntity>, int>((ref, rideId) {
      final streamDriverLocation = ref.watch(
        streamDriverLocationUseCaseProvider,
      );

      ref.onDispose(() {
        ref.read(rideSocketServiceProvider).disconnect();
      });

      final stream = streamDriverLocation(rideId);

      return stream.map((either) {
        return either.fold(
          (failure) {
            return AsyncValue.error(failure, StackTrace.current);
          },
          (driverLocation) {
            return AsyncValue.data(driverLocation);
          },
        );
      });
    });
