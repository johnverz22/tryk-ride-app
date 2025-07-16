import 'package:user/features/ride/data/datasources/ride_remote_datasource.dart';
import 'package:user/features/ride/domain/repositories/ride_repository.dart';
import 'package:user/features/ride/domain/entities/ride.dart';
import 'package:user/features/ride/data/models/ride_model.dart';
import 'package:user/features/ride/domain/entities/ride_details.dart';

class RideRepositoryImpl implements RideRepository {
  final RideRemoteDatasource remote;

  RideRepositoryImpl(this.remote);

  @override
  Future<int> requestRide(Ride request) {
    final model = RideModel.fromEntity(request);
    return remote.requestRide(model);
  }

  @override
  Future<void> cancelRide(int rideId) {
    return remote.cancelRide(rideId);
  }

  @override
  Future<RideDetails> fetchRideDetails(int rideId) {
    return remote.fetchRideDetails(rideId);
  }
}
