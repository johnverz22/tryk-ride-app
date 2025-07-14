import 'package:dio/dio.dart';
import '../models/ride_request_model.dart';

abstract class RideRemoteDatasource {
  Future<void> requestRide(RideRequestModel model);
}

class RideRemoteDatasourceImpl implements RideRemoteDatasource {
  final Dio dio;

  RideRemoteDatasourceImpl(this.dio);

  @override
  Future<void> requestRide(RideRequestModel model) async {
    await dio.post('/rides/request', data: model.toJson());
  }
}
