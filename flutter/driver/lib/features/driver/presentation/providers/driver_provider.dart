import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/models/driver_model.dart';

class DriverProvider with ChangeNotifier {
  DriverModel? _driver;
  String? _token;
  bool _isOnline = false; // Online status of the driver

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  DriverProvider() {
    loadDriverData();
  }

  DriverModel? get driver => _driver;
  String? get token => _token;
  bool get isOnline => _isOnline;

  bool get isAuthenticated => _driver != null && _token != null;

  /// Sets driver and token, persists them securely
  Future<void> setDriver(DriverModel driver, String token) async {
    _driver = driver;
    _token = token;
    await _storage.write(key: 'token', value: token);
    await _storage.write(key: 'driver', value: jsonEncode(driver.toJson()));
    notifyListeners();
  }

  /// Updates only the token
  Future<void> setToken(String token) async {
    _token = token;
    await _storage.write(key: 'token', value: token);
    notifyListeners();
  }

  /// Loads driver, token and online status from secure storage
  Future<void> loadDriverData() async {
    final token = await _storage.read(key: 'token');
    final driverJson = await _storage.read(key: 'driver');
    final isOnlineStr = await _storage.read(key: 'isOnline');

    if (token != null) _token = token;

    if (driverJson != null) {
      try {
        final driverMap = jsonDecode(driverJson);
        _driver = DriverModel.fromJson(json: driverMap);
      } catch (e) {
        debugPrint('[DriverProvider] Error decoding driver: $e');
      }
    }

    if (isOnlineStr != null) {
      _isOnline = isOnlineStr.toLowerCase() == 'true';
    }

    notifyListeners();
  }

  /// Sets online status and persists it
  Future<void> setOnline(bool value) async {
    _isOnline = value;
    await _storage.write(key: 'isOnline', value: value.toString());
    notifyListeners();
  }

  /// Alias to setOnline for semantic clarity
  Future<void> setOnlineStatus(bool value) => setOnline(value);

  /// Clears stored data and resets state
  Future<void> logout() async {
    _driver = null;
    _token = null;
    _isOnline = false;
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'driver');
    await _storage.delete(key: 'isOnline');
    notifyListeners();
  }
}
