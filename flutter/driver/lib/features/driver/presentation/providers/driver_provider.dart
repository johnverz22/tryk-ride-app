import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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
  List<Map<String, dynamic>> _trips = []; // ✅ ADDED TRIPS FIELD

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
  List<Map<String, dynamic>> get trips => _trips; // ✅ ADDED GETTER

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
    _trips.clear(); // ✅ CLEAR TRIPS ON LOGOUT
    _stopPolling();
    await _storage.deleteAll();
    notifyListeners();
  }

  // Polling every 5 seconds
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_isOnline && _token != null) fetchRequestedRides();
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

  Future<RideRequest?> acceptRequest(RideRequest ride) async {
    try {
      final rideStatusUrl = Uri.parse('${ApiConfig.baseUrl}/rides/${ride.id}');
      final acceptRideUrl = Uri.parse(
        '${ApiConfig.baseUrl}/rides/${ride.id}/accept',
      );

      final headers = {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      };

      // 1. Get latest ride info
      final statusRes = await http.get(rideStatusUrl, headers: headers);
      if (statusRes.statusCode != 200) return null;

      final rideJson = json.decode(statusRes.body);
      final status = rideJson['status']?['name'] ?? '';

      debugPrint(
        'statusRes Ride Response: ${statusRes.statusCode} - ${statusRes.body}',
      );

      if (status != 'Requested') return null;

      // 2. Accept the ride
      final acceptRes = await http.post(acceptRideUrl, headers: headers);
      if (acceptRes.statusCode != 200) return null;

      // 3. Build updated ride
      final updatedRide = RideRequest.fromJson(rideJson);

      // 4. Remove from local list and notify
      _requestedRides.removeWhere((r) => r.id == ride.id);
      notifyListeners();

      return updatedRide;
    } catch (e) {
      debugPrint('Accept error: $e');
      return null;
    }
  }

  Future<void> rejectRide(RideRequest ride) async {
    if (_token == null) return;

    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/rides/${ride.id}/reject'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      _rejectedRideIds.add(ride.id);
      _requestedRides.removeWhere((r) => r.id == ride.id);
      _hasIncomingRequest = _requestedRides.isNotEmpty;
      debugPrint('Ride rejected successfully');
      notifyListeners();
    } else {
      debugPrint('Failed to reject ride: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
    }
  }

  Future<void> rejectSpecificRide(RideRequest ride) async {
    _rejectedRideIds.add(ride.id);
    _requestedRides.removeWhere((r) => r.id == ride.id);
    _hasIncomingRequest = _requestedRides.isNotEmpty;
    notifyListeners();

    await fetchRequestedRides();
  }

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
      final newRides = (data as List)
          .map((e) => RideRequest.fromJson(e))
          .where((ride) => !_rejectedRideIds.contains(ride.id))
          .toList();

      _requestedRides = newRides;
      _hasIncomingRequest = _requestedRides.isNotEmpty;
      notifyListeners();
    } else {
      debugPrint(
        'Failed to fetch rides: ${response.statusCode} → ${response.body}',
      );
    }
  }

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
      switch (method.toUpperCase()) {
        case 'PUT':
          response = await http.put(uri, headers: headers, body: body);
        case 'POST':
          response = await http.post(uri, headers: headers, body: body);
        case 'GET':
          response = await http.get(uri, headers: headers);
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
        default:
          throw UnimplementedError('Method $method not supported');
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

  /// ✅ UPDATED: Fetch trips and store them locally
  Future<void> fetchDriverTrips() async {
    if (_token == null) return;

    final url = Uri.parse('${ApiConfig.baseUrl}/driver/trips');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $_token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Debug: Print the actual response structure
      debugPrint('API Response type: ${data.runtimeType}');
      debugPrint('API Response: $data');

      // Handle paginated response
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        // Paginated response
        _trips = List<Map<String, dynamic>>.from(data['data']);
        debugPrint('Extracted ${_trips.length} trips from paginated response');
      } else if (data is List) {
        // Direct array response
        _trips = List<Map<String, dynamic>>.from(data);
        debugPrint('Got ${_trips.length} trips from direct array response');
      } else {
        debugPrint('Unexpected response format: ${data.runtimeType}');
        _trips = [];
      }

      // Debug: Print first trip if available
      if (_trips.isNotEmpty) {}

      notifyListeners();
    } else {
      debugPrint(
        'Failed to fetch trips: ${response.statusCode} → ${response.body}',
      );
      _trips = [];
      notifyListeners();
    }
  }
}
