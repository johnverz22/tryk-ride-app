import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../data/models/driver_model.dart';
import '../../data/models/ride_request_model.dart';
import '../../core/config/api_config.dart';

class DriverState {
  final DriverModel? driver;
  final String? token;
  final bool isOnline;
  final bool hasIncomingRequest;
  final List<RideRequest> requestedRides;
  final List<Map<String, dynamic>> trips;
  final bool isLoading;

  DriverState({
    this.driver,
    this.token,
    this.isOnline = false,
    this.hasIncomingRequest = false,
    this.requestedRides = const [],
    this.trips = const [],
    this.isLoading = false,
  });

  DriverState copyWith({
    DriverModel? driver,
    String? token,
    bool? isOnline,
    bool? hasIncomingRequest,
    List<RideRequest>? requestedRides,
    List<Map<String, dynamic>>? trips,
    bool? isLoading,
  }) {
    return DriverState(
      driver: driver ?? this.driver,
      token: token ?? this.token,
      isOnline: isOnline ?? this.isOnline,
      hasIncomingRequest: hasIncomingRequest ?? this.hasIncomingRequest,
      requestedRides: requestedRides ?? this.requestedRides,
      trips: trips ?? this.trips,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class DriverNotifier extends StateNotifier<DriverState> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Set<int> _rejectedRideIds = {};
  Timer? _pollingTimer;

  DriverNotifier() : super(DriverState()) {
    loadDriverData();
  }

  // Authentication & State
  Future<void> setDriver(DriverModel driver, String token) async {
    await _storage.write(key: 'token', value: token);
    await _storage.write(key: 'driver', value: jsonEncode(driver.toJson()));
    state = state.copyWith(driver: driver, token: token);
  }

  Future<void> setToken(String token) async {
    await _storage.write(key: 'token', value: token);
    state = state.copyWith(token: token);
  }

  Future<void> loadDriverData() async {
    final token = await _storage.read(key: 'token');
    final driverJson = await _storage.read(key: 'driver');
    final isOnlineStr = await _storage.read(key: 'isOnline');

    DriverModel? driver;

    if (driverJson != null) {
      try {
        final driverMap = jsonDecode(driverJson);
        driver = DriverModel.fromJson(json: driverMap);
      } catch (e) {
        debugPrint('[DriverProvider] Error decoding driver: $e');
      }
    }

    final isOnline = isOnlineStr?.toLowerCase() == 'true';

    state = state.copyWith(
      driver: driver,
      token: token,
      isOnline: isOnline,
    );

    if (isOnline) _startPolling();
  }

  Future<void> setOnline(bool value) async {
    await _storage.write(key: 'isOnline', value: value.toString());

    if (value) {
      _startPolling();
    } else {
      _stopPolling();
    }

    state = state.copyWith(
      isOnline: value,
      requestedRides: [],
      hasIncomingRequest: false,
    );
  }

  Future<void> logout() async {
    _stopPolling();
    await _storage.deleteAll();
    state = DriverState();
  }
  // Polling every 5 seconds
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (state.isOnline && state.token != null) fetchRequestedRides();
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> fetchRequestedRides() async {
    if (state.token == null) return;

    final url = Uri.parse('${ApiConfig.baseUrl}/driver/requested-rides');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer ${state.token}',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final newRides = (data as List)
          .map((e) => RideRequest.fromJson(e))
          .where((ride) => !_rejectedRideIds.contains(ride.id))
          .toList();
      state = state.copyWith(
        requestedRides: newRides,
        hasIncomingRequest: newRides.isNotEmpty,
      );
    } else {
      debugPrint(
        'Failed to fetch rides: ${response.statusCode} → ${response.body}',
      );
    }
  }

  Future<void> rejectRide(RideRequest ride) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/rides/${ride.id}/reject'),
      headers: {
        'Authorization': 'Bearer ${state.token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      _rejectedRideIds.add(ride.id);
      final updated = List<RideRequest>.from(state.requestedRides)
        ..removeWhere((r) => r.id == ride.id);
      debugPrint('Ride rejected successfully');
      state = state.copyWith(
        requestedRides: updated,
        hasIncomingRequest: updated.isNotEmpty,
      );
    } else {
      debugPrint('Failed to reject ride: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
    }
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}