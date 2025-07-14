import '../../domain/entities/ride_request.dart';
import '../../domain/repositories/ride_repository.dart';
import '../datasources/ride_remote_datasource.dart';
import '../models/ride_request_model.dart';

class RideRepositoryImpl implements RideRepository {
  final RideRemoteDatasource remote;

  RideRepositoryImpl(this.remote);

  @override
  Future<void> requestRide(RideRequest request) {
    final model = RideRequestModel.fromEntity(request);
    return remote.requestRide(model);
  }
}
