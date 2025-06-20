import 'package:dio/dio.dart';

import '../../../../../core/errors/exceptions.dart';
import '../../../../../core/params/params.dart';
import '../models/driver_model.dart';

abstract class DriverRemoteDataSource {
  Future<DriverModel> getDriver({required DriverParams driverParams});
}

class DriverRemoteDataSourceImpl implements DriverRemoteDataSource {
  final Dio dio;

  DriverRemoteDataSourceImpl({required this.dio});

  @override
  Future<DriverModel> getDriver({required DriverParams driverParams}) async {
    final response = await dio.get(
      'https://your-api-url.com/api/drivers/${driverParams.id}',
      queryParameters: {
        // Include query params if needed
        // 'api_key': 'your-api-key',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return DriverModel.fromJson(json: response.data);
    } else {
      throw ServerException();
    }
  }
}
