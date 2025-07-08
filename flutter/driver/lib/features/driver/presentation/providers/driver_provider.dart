import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../data/models/driver_model.dart';
import '../../data/models/ride_request_model.dart';

class DriverState {
  final DriverModel? driver;
  final String? token;
  final bool isOnline;
  final List<RideRequest> requestedRides;
  final List<Map<String, dynamic>> trips;

  const DriverState({
    this.driver,
    this.token,
    this.isOnline = false,
    this.requestedRides = const [],
    this.trips = const [],
  });

  bool get isAuthenticated => driver != null && token != null;

  DriverState copyWith({
    DriverModel? driver,
    String? token,
    bool? isOnline,
    List<RideRequest>? requestedRides,
    List<Map<String, dynamic>>? trips,
  }) {
    return DriverState(
      driver: driver ?? this.driver,
      token: token ?? this.token,
      isOnline: isOnline ?? this.isOnline,
      requestedRides: requestedRides ?? this.requestedRides,
      trips: trips ?? this.trips,
    );
  }
}

class DriverNotifier extends AsyncNotifier<DriverState?> {
  final _storage = const FlutterSecureStorage();
  final Set<int> _rejectedRideIds = {};
  Timer? _pollingTimer;

  Position? _lastPosition;
  DateTime? _lastPositionTime;

  String? get baseUrl => dotenv.env['BASE_URL'];

  @override
  Future<DriverState> build() async {
    final token = await _storage.read(key: 'token');
    final driverJson = await _storage.read(key: 'driver');
    final isOnlineStr = await _storage.read(key: 'isOnline');

    DriverModel? driver;

    if (driverJson != null) {
      try {
        driver = DriverModel.fromJson(json: jsonDecode(driverJson));
      } catch (e) {
        debugPrint('[DriverNotifier] Error decoding driver: $e');
      }
    }

    final isOnline = isOnlineStr == 'true';

    if (isOnline && token != null) {
      _startPolling();
    }

    return DriverState(driver: driver, token: token, isOnline: isOnline);
  }

  Future<void> updateDriver(DriverModel updatedDriver) async {
    final current = state.value;
    if (current?.token == null || baseUrl == null) return;

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/driver/update'),
        headers: _authHeaders(current!.token!),
        body: jsonEncode(updatedDriver.toJson()),
      );

      if (response.statusCode == 200) {
        await _storage.write(
          key: 'driver',
          value: jsonEncode(updatedDriver.toJson()),
        );

        state = AsyncData(current.copyWith(driver: updatedDriver));
      } else {
        debugPrint('Failed to update driver: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error in updateDriver: $e');
    }
  }

  Future<bool> ensureLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  Future<Position> _getFreshPosition({
    Duration cacheDuration = const Duration(seconds: 15),
  }) async {
    final now = DateTime.now();
    if (_lastPosition != null &&
        _lastPositionTime != null &&
        now.difference(_lastPositionTime!) < cacheDuration) {
      return _lastPosition!;
    }

    _lastPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    _lastPositionTime = now;
    return _lastPosition!;
  }

  Future<void> toggleOnline(bool value) async {
    final current = state.value;
    if (current?.token == null) return;

    final hasPermission = await ensureLocationPermission();
    if (!hasPermission) {
      debugPrint('Location permission denied.');
      return;
    }

    try {
      final position = await _getFreshPosition();

      final res = await http.post(
        Uri.parse('$baseUrl/driver/update-location'),
        headers: _authHeaders(current!.token!),
        body: jsonEncode({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'is_online': value,
        }),
      );

      if (res.statusCode == 200) {
        await _storage.write(key: 'isOnline', value: value.toString());

        value ? _startPolling() : _stopPolling();

        state = AsyncData(current.copyWith(isOnline: value));
      } else {
        debugPrint('Failed to set online status: ${res.body}');
      }
    } catch (e) {
      debugPrint('Error setting online status: $e');
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      fetchRequestedRides();
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> fetchRequestedRides() async {
    debugPrint('Fetching requested rides...');
    final current = state.value;
    if (current == null || !current.isOnline) return;

    try {
      final position = await _getFreshPosition();

      await http.post(
        Uri.parse('$baseUrl/driver/update-location'),
        headers: _authHeaders(current.token!),
        body: jsonEncode({
          'latitude': position.latitude,
          'longitude': position.longitude,
        }),
      );

      final res = await http.get(
        Uri.parse('$baseUrl/driver/requested-rides'),
        headers: _authHeaders(current.token!),
      );

      debugPrint(res.body);

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final data = json['rides'] as List<dynamic>;
        debugPrint('Fetched rides from server: ${data.length}');

        final rides = data
            .map((e) => RideRequest.fromJson(e))
            .where((r) => !_rejectedRideIds.contains(r.id))
            .toList();

        if (!_areRideListsEqual(current.requestedRides, rides)) {
          debugPrint('Updating state with new rides...');
          state = AsyncData(current.copyWith(requestedRides: rides));
        } else {
          debugPrint('No change in ride list, skipping update.');
        }
      } else {
        debugPrint('Server error: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      debugPrint('Fetch rides error: $e');
    }
  }

  Future<RideRequest?> acceptRide(RideRequest ride) async {
    final current = state.value;
    if (current?.token == null) return null;

    try {
      final rideStatusUrl = Uri.parse('$baseUrl/rides/${ride.id}');
      final acceptRideUrl = Uri.parse('$baseUrl/rides/${ride.id}/accept');
      final headers = _authHeaders(current!.token!);

      final statusRes = await http.get(rideStatusUrl, headers: headers);
      if (statusRes.statusCode != 200) return null;

      final rideJson = jsonDecode(statusRes.body);
      final status = rideJson['status']?['name'] ?? '';
      if (status != 'Requested') return null;

      final acceptRes = await http.post(acceptRideUrl, headers: headers);
      if (acceptRes.statusCode != 200) return null;

      final updatedRide = RideRequest.fromJson(rideJson);

      final updatedRides = current.requestedRides
          .where((r) => r.id != ride.id)
          .toList();

      state = AsyncData(current.copyWith(requestedRides: updatedRides));
      return updatedRide;
    } catch (e) {
      debugPrint('Accept ride error: $e');
      return null;
    }
  }

  Future<void> rejectRide(RideRequest ride) async {
    final current = state.value;
    if (current?.token == null) return;

    try {
      await http.patch(
        Uri.parse('$baseUrl/rides/${ride.id}/reject'),
        headers: _authHeaders(current!.token!),
      );

      _rejectedRideIds.add(ride.id);

      final updatedRides = current.requestedRides
          .where((r) => r.id != ride.id)
          .toList();

      state = AsyncData(current.copyWith(requestedRides: updatedRides));
    } catch (e) {
      debugPrint('Reject ride error: $e');
    }
  }

  Future<void> fetchTrips() async {
    final current = state.value;

    if (current?.token == null) return;

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/driver/trips'),
        headers: _authHeaders(current!.token!),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final trips = data is List
            ? List<Map<String, dynamic>>.from(data)
            : List<Map<String, dynamic>>.from(data['data'] ?? []);

        final updated = current.copyWith(trips: trips);

        state = AsyncData(updated);
      }
    } catch (e) {
      debugPrint('❌ Fetch trips error: $e');
    }
  }

  Future<void> setDriver(DriverModel? driver, String? token) async {
    if (driver == null || token == null) {
      await _storage.delete(key: 'token');
      await _storage.delete(key: 'driver');
      state = AsyncData(null);
      return;
    }

    await _storage.write(key: 'token', value: token);
    await _storage.write(key: 'driver', value: jsonEncode(driver.toJson()));
    state = AsyncData(DriverState(driver: driver, token: token));
  }

  Future<void> logout() async {
    _stopPolling();
    await _storage.deleteAll();
    state = const AsyncData(DriverState());
  }

  Map<String, String> _authHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  bool _areRideListsEqual(List<RideRequest> a, List<RideRequest> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }
}

// ───── Riverpod Provider ─────
final driverProvider = AsyncNotifierProvider<DriverNotifier, DriverState?>(
  () => DriverNotifier(),
);
