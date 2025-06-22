import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/models/driver_model.dart';

// Define the state class for the driver
class DriverState {
  final DriverModel? driver;
  final String? token;
  final bool isLoading;

  DriverState({
    this.driver,
    this.token,
    this.isLoading = false,
  });

  bool get isAuthenticated => driver != null && token != null;

  DriverState copyWith({
    DriverModel? driver,
    String? token,
    bool? isLoading,
  }) {
    return DriverState(
      driver: driver ?? this.driver,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Define a StateNotifier to manage the driver state
class DriverNotifier extends StateNotifier<DriverState> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  DriverNotifier() : super(DriverState()) {
    loadDriverData();
  }

  Future<void> setDriver(DriverModel driver, String token) async {
    state = state.copyWith(isLoading: true);
    await _storage.write(key: 'token', value: token);
    await _storage.write(key: 'driver', value: jsonEncode(driver.toJson()));
    state = state.copyWith(
      driver: driver,
      token: token,
      isLoading: false,
    );
  }

  Future<void> setToken(String token) async {
    state = state.copyWith(isLoading: true);
    await _storage.write(key: 'token', value: token);
    state = state.copyWith(
      token: token,
      isLoading: false,
    );
  }

  Future<void> loadDriverData() async {
    state = state.copyWith(isLoading: true);
    final token = await _storage.read(key: 'token');
    final driverJson = await _storage.read(key: 'driver');

    DriverModel? driver;
    if (driverJson != null) {
      try {
        final driverMap = jsonDecode(driverJson);
        driver = DriverModel.fromJson(json: driverMap);
      } catch (e) {
        debugPrint('[DriverNotifier] Error decoding driver: $e');
      }
    }

    state = state.copyWith(
      driver: driver,
      token: token,
      isLoading: false,
    );
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'driver');
    state = DriverState(isLoading: false);
  }
}

// Create a StateNotifierProvider that will be used to access the DriverNotifier
final driverProvider = StateNotifierProvider<DriverNotifier, DriverState>((ref) {
  return DriverNotifier();
});

// Keep the old provider for backward compatibility during migration
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
