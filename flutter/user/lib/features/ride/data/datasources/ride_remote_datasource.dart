import 'package:dio/dio.dart';
import '../models/ride_model.dart';

abstract class RideRemoteDatasource {
  Future<int> requestRide(RideModel model);

  Future<void> cancelRide(int rideId) async {}
}

class RideRemoteDatasourceImpl implements RideRemoteDatasource {
  final Dio dio;

  RideRemoteDatasourceImpl(this.dio);

  @override
  Future<int> requestRide(RideModel model) async {
    final payload = model.toJson();

    final response = await dio.post('/api/rides/request', data: payload);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data;

      if (data != null && data['ride']['id'] != null) {
        return data['ride']['id'] as int;
      } else {
        throw Exception('Ride ID not found in response');
      }
    } else {
      throw Exception('Failed to request ride: ${response.statusCode}');
    }
  }

  @override
  Future<void> cancelRide(int rideId) async {
    await dio.post('/api/rides/cancel', data: {'ride_id': rideId});
  }
}
