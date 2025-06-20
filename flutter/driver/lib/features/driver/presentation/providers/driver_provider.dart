import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/models/driver_model.dart';

class DriverProvider with ChangeNotifier {
  DriverModel? _driver;
  String? _token;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  DriverProvider() {
    loadDriverData();
  }

  DriverModel? get driver => _driver;
  String? get token => _token;

  bool get isAuthenticated => _driver != null && _token != null;

  Future<void> setDriver(DriverModel driver, String token) async {
    _driver = driver;
    _token = token;
    await _storage.write(key: 'token', value: token);
    await _storage.write(key: 'driver', value: jsonEncode(driver.toJson()));
    notifyListeners();
  }

  Future<void> setToken(String token) async {
    _token = token;
    await _storage.write(key: 'token', value: token);
    notifyListeners();
  }

  Future<void> loadDriverData() async {
    final token = await _storage.read(key: 'token');
    final driverJson = await _storage.read(key: 'driver');

    if (token != null) _token = token;

    if (driverJson != null) {
      try {
        final driverMap = jsonDecode(driverJson);
        _driver = DriverModel.fromJson(json: driverMap);
      } catch (e) {
        debugPrint('[DriverProvider] Error decoding driver: $e');
      }
    }

    notifyListeners();
  }

  Future<void> logout() async {
    _driver = null;
    _token = null;
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'driver');
    notifyListeners();
  }
}
