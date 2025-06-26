import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../data/models/driver_model.dart';
import '../../data/models/ride_request_model.dart';
import '../../../../core/config/api_config.dart';

class DriverProvider with ChangeNotifier {
  DriverModel? _driver;
  String? _token;
  bool _isOnline = false;
  bool _hasIncomingRequest = false;

  final Set<int> _rejectedRideIds = {};

  List<RideRequest> _requestedRides = [];
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Timer? _pollingTimer;

  DriverProvider() {
    loadDriverData();
  }

  // Getters
  DriverModel? get driver => _driver;
  String? get token => _token;
  bool get isOnline => _isOnline;
  bool get isAuthenticated => _driver != null && _token != null;
  bool get hasIncomingRequest => _hasIncomingRequest;
  List<RideRequest> get requestedRides => _requestedRides;

  // Authentication & State
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
      if (_isOnline) _startPolling();
    }

    notifyListeners();
  }

  Future<void> setOnline(bool value) async {
    _isOnline = value;
    await _storage.write(key: 'isOnline', value: value.toString());

    if (value) {
      _startPolling();
    } else {
      _stopPolling();
      _requestedRides.clear();
      _hasIncomingRequest = false;
    }

    notifyListeners();
  }

  Future<void> setOnlineStatus(bool value) => setOnline(value);

  Future<void> logout() async {
    _driver = null;
    _token = null;
    _isOnline = false;
    _hasIncomingRequest = false;
    _requestedRides.clear();
    _stopPolling();
    await _storage.deleteAll();
    notifyListeners();
  }

  // Polling every 5 seconds
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      fetchRequestedRides();
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  // Ride request actions
  Future<bool> acceptRequest(RideRequest ride) async {
    try {
      final rideStatusUrl = Uri.parse('${ApiConfig.baseUrl}/rides/${ride.id}');
      final acceptRideUrl = Uri.parse(
        '${ApiConfig.baseUrl}/rides/${ride.id}/accept',
      );

      final headers = {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      };

      // Step 1: Check current ride status
      final statusRes = await http.get(rideStatusUrl, headers: headers);
      if (statusRes.statusCode != 200) return false;

      final status =
          json.decode(statusRes.body)['ride']?['status']?['name'] ?? '';
      if (status != 'Requested') return false;

      // Step 2: Try accepting the ride
      final acceptRes = await http.post(acceptRideUrl, headers: headers);
      if (acceptRes.statusCode != 200) return false;

      // Step 3: Update local state
      requestedRides.removeWhere((r) => r.id == ride.id);
      notifyListeners();

      return true;
    } catch (e) {
      // Optionally log the error here
      return false;
    }
  }

  void rejectSpecificRide(RideRequest ride) {
    _rejectedRideIds.add(ride.id);
    _requestedRides.removeWhere((r) => r.id == ride.id);
    _hasIncomingRequest = _requestedRides.isNotEmpty;
    notifyListeners();
  }

  // Fetch ride requests via HTTP (every 5 seconds)
  Future<void> fetchRequestedRides() async {
    if (_token == null) return;

    final url = Uri.parse('${ApiConfig.baseUrl}/driver/requested-rides');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $_token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _requestedRides = (data as List)
          .map((e) => RideRequest.fromJson(e))
          .where((ride) => !_rejectedRideIds.contains(ride.id))
          .toList();
      _hasIncomingRequest = _requestedRides.isNotEmpty;
      notifyListeners();
    } else {
      debugPrint('Failed to fetch rides: ${response.body}');
    }
  }

  // Token refresh logic
  Future<bool> refreshToken() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/refresh'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['token'];
        if (newToken != null) {
          await setToken(newToken);
          return true;
        }
      }
    } catch (e) {
      debugPrint('Token refresh failed: $e');
    }

    return false;
  }

  // Reusable authenticated request method
  Future<http.Response> authenticatedRequest(
    String url,
    String method, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    headers ??= {};
    final token = await _storage.read(key: 'token');
    if (token != null) headers['Authorization'] = 'Bearer $token';

    http.Response response;
    final uri = Uri.parse(url);

    try {
      if (method == 'PUT') {
        response = await http.put(uri, headers: headers, body: body);
      } else {
        throw UnimplementedError('Method not supported');
      }

      if (response.statusCode == 401) {
        final refreshed = await refreshToken();
        if (refreshed) {
          final newToken = await _storage.read(key: 'token');
          if (newToken != null) headers['Authorization'] = 'Bearer $newToken';
          response = await http.put(uri, headers: headers, body: body);
        }
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateDriver(DriverModel updatedDriver) async {
    if (_token == null) return;

    final response = await authenticatedRequest(
      '${ApiConfig.baseUrl}/driver/update',
      'PUT',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updatedDriver.toJson()),
    );

    if (response.statusCode == 200) {
      _driver = updatedDriver;
      await _storage.write(
        key: 'driver',
        value: jsonEncode(updatedDriver.toJson()),
      );
      notifyListeners();
    } else {
      debugPrint('Failed to update driver: ${response.body}');
    }
  }
}
