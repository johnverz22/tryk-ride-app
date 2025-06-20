import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/errors/exceptions.dart';
import '../models/driver_model.dart';

abstract class DriverLocalDataSource {
  Future<void> cacheDriver({required DriverModel? driverToCache});
  Future<DriverModel> getLastDriver();
}

const cachedDriver = 'CACHED_DRIVER';

class DriverLocalDataSourceImpl implements DriverLocalDataSource {
  final SharedPreferences sharedPreferences;

  DriverLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<DriverModel> getLastDriver() {
    final jsonString = sharedPreferences.getString(cachedDriver);

    if (jsonString != null) {
      return Future.value(DriverModel.fromJson(json: json.decode(jsonString)));
    } else {
      throw CacheException();
    }
  }

  @override
  Future<void> cacheDriver({required DriverModel? driverToCache}) async {
    if (driverToCache != null) {
      sharedPreferences.setString(
        cachedDriver,
        json.encode(driverToCache.toJson()),
      );
    } else {
      throw CacheException();
    }
  }
}
