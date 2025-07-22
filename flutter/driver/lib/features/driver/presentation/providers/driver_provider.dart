import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:driver/features/driver/data/services/driver_socket_service.dart';
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

  DriverSocketService? _socketService;
  StreamSubscription? _rideRequestSubscription;
  StreamSubscription? _rideCancellationSubscription;
  Position? _lastPosition;
  DateTime? _lastPositionTime;

  String? get baseUrl => dotenv.env['BASE_URL'];

  @override
  Future<DriverState> build() {
    ref.onDispose(() {
      _stopRealtimeUpdates();
    });

    _socketService = DriverSocketService(Dio());
    return _loadInitialState();
  }

  Future<DriverState> _loadInitialState() async {
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

    if (isOnline && token != null && driver != null) {
      _startRealtimeUpdates(driver.id, token);
    }

    return DriverState(driver: driver, token: token, isOnline: isOnline);
  }

  void _startRealtimeUpdates(int driverId, String token) {
    if (_socketService == null) return;
    _socketService!.init(driverId);

    _rideRequestSubscription?.cancel();
    _rideRequestSubscription = _socketService!.rideRequestStream.listen(
      (rideData) {
        final newRide = RideRequest.fromJson(rideData);
        _handleNewRideRequest(newRide);
      },
      onError: (error) =>
          debugPrint('[DriverNotifier] Ride stream error: $error'),
    );

    _rideCancellationSubscription?.cancel();
    _rideCancellationSubscription = _socketService!.rideCancellationStream
        .listen(
          (cancelledRideId) {
            _handleRideCancellation(cancelledRideId);
          },
          onError: (error) => debugPrint(
            '[DriverNotifier] Ride cancellation stream error: $error',
          ),
        );
  }

  void _stopRealtimeUpdates() {
    _rideRequestSubscription?.cancel();
    _rideRequestSubscription = null;
    _rideCancellationSubscription?.cancel();
    _rideCancellationSubscription = null;
    _socketService?.disconnect();
  }

  void _handleNewRideRequest(RideRequest ride) {
    final current = state.value;
    if (current == null || !current.isOnline) return;

    if (_rejectedRideIds.contains(ride.id) ||
        current.requestedRides.any((r) => r.id == ride.id)) {
      debugPrint(
        '[DriverNotifier] Ignoring duplicate or rejected ride ID: ${ride.id}',
      );
      return;
    }

    final updatedRides = List<RideRequest>.from(current.requestedRides)
      ..add(ride);
    state = AsyncData(current.copyWith(requestedRides: updatedRides));
  }

  void _handleRideCancellation(int cancelledRideId) {
    final current = state.value;
    if (current == null) return;

    final updatedRides = current.requestedRides
        .where((ride) => ride.id != cancelledRideId)
        .toList();

    debugPrint('[DriverNotifier] Removing cancelled ride ID: $cancelledRideId');

    state = AsyncData(current.copyWith(requestedRides: updatedRides));
  }

  Future<void> toggleOnline(bool value) async {
    final currentAsyncState = state;
    final currentStateValue = state.value;

    if (currentStateValue == null || !currentStateValue.isAuthenticated) return;

    if (value) {
      // --- Going ONLINE ---
      final hasPermission = await ensureLocationPermission();
      if (!hasPermission) return; // Don't change state if permission is denied

      // Enter a loading state, while keeping previous data for the UI
      state = const AsyncLoading<DriverState?>().copyWithPrevious(
        currentAsyncState,
      );

      final position = await _getFreshPosition();
      final success = await _updateLocationAndStatus(position, isOnline: true);

      if (success) {
        // If the API call is successful, update storage and start services
        await _storage.write(key: 'isOnline', value: 'true');
        _startRealtimeUpdates(
          currentStateValue.driver!.id,
          currentStateValue.token!,
        );

        // This will fetch rides and update the state internally
        await fetchInitialRequestedRides();

        // Ensure the final state reflects 'isOnline: true'
        // This takes the most recent state (which might include new rides)
        // and applies the isOnline flag.
        state = AsyncData(state.value!.copyWith(isOnline: true));
      } else {
        // If the API call fails, revert to the original state
        state = currentAsyncState;
        // You might want to show an error message to the user here
      }
    } else {
      // --- Going OFFLINE (Corrected Logic from previous step) ---

      // 1. Immediately disconnect from realtime updates.
      _stopRealtimeUpdates();

      // 2. Optimistically update the state and persistent storage.
      //    The UI will now show "offline" and it will stick.
      state = AsyncData(
        currentStateValue.copyWith(isOnline: false, requestedRides: []),
      );
      await _storage.write(key: 'isOnline', value: 'false');

      // 3. Attempt to sync the "offline" status with the backend in the background.
      //    We no longer revert the state if this fails.
      await _updateLocationAndStatus(null, isOnline: false);
    }
  }

  Future<bool> _updateLocationAndStatus(
    Position? position, {
    required bool isOnline,
  }) async {
    final current = state.value;
    if (current == null || !current.isAuthenticated) return false;

    try {
      final Map<String, dynamic> body = {'is_online': isOnline};
      if (position != null) {
        body['latitude'] = position.latitude;
        body['longitude'] = position.longitude;
      }

      final res = await http.post(
        Uri.parse('$baseUrl/api/driver/update-location'),
        headers: _authHeaders(current.token!),
        body: jsonEncode(body),
      );

      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Error in _updateLocationAndStatus: $e');
      return false;
    }
  }

  Future<void> fetchInitialRequestedRides() async {
    final current = state.value;
    if (current == null || !current.isAuthenticated || !current.isOnline)
      return;

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/driver/requested-rides'),
        headers: _authHeaders(current.token!),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['rides'] as List<dynamic>;
        final rides = data
            .map((e) => RideRequest.fromJson(e))
            .where((r) => !_rejectedRideIds.contains(r.id))
            .toList();

        if (!listEquals(current.requestedRides, rides)) {
          state = AsyncData(current.copyWith(requestedRides: rides));
        }
      }
    } catch (e) {
      debugPrint('Fetch initial rides error: $e');
    }
  }

  Future<RideRequest?> acceptRide(RideRequest ride) async {
    final current = state.value;
    if (current == null || !current.isAuthenticated) return null;

    final originalRides = current.requestedRides;
    final updatedRides = originalRides.where((r) => r.id != ride.id).toList();
    state = AsyncData(current.copyWith(requestedRides: updatedRides));

    try {
      final acceptRes = await http.post(
        Uri.parse('$baseUrl/api/rides/${ride.id}/accept'),
        headers: _authHeaders(current.token!),
      );

      if (acceptRes.statusCode == 200) {
        final updatedRideJson = jsonDecode(acceptRes.body);
        return RideRequest.fromJson(updatedRideJson['ride']);
      } else {
        debugPrint('Accept ride failed: ${acceptRes.body}');
        return null;
      }
    } catch (e) {
      state = AsyncData(current.copyWith(requestedRides: originalRides));
      debugPrint('Accept ride error: $e');
      return null;
    }
  }

  Future<void> rejectRide(RideRequest ride) async {
    final current = state.value;
    if (current == null || !current.isAuthenticated) return;

    _rejectedRideIds.add(ride.id);
    final updatedRides = current.requestedRides
        .where((r) => r.id != ride.id)
        .toList();
    state = AsyncData(current.copyWith(requestedRides: updatedRides));

    try {
      await http.patch(
        Uri.parse('$baseUrl/api/rides/${ride.id}/reject'),
        headers: _authHeaders(current.token!),
      );
    } catch (e) {
      debugPrint('Reject ride error: $e');
    }
  }

  Future<void> fetchTrips() async {
    final current = state.value;
    if (current == null || !current.isAuthenticated) return;

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/driver/trips'),
        headers: _authHeaders(current.token!),
      );

      if (res.statusCode == 200) {
        final decodedJson = jsonDecode(res.body);

        List<dynamic> rawTripsList;

        if (decodedJson is Map && decodedJson.containsKey('data')) {
          rawTripsList = decodedJson['data'] as List<dynamic>;
        } else if (decodedJson is List) {
          rawTripsList = decodedJson;
        } else {
          debugPrint('❌ Fetch trips error: Unexpected JSON format.');
          return;
        }

        final trips = List<Map<String, dynamic>>.from(rawTripsList);
        state = AsyncData(current.copyWith(trips: trips));
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Fetch trips error: $e');
      debugPrint('❌ StackTrace: $stackTrace');
    }
  }

  Future<void> updateDriver(DriverModel updatedDriver) async {
    final current = state.value;
    if (current == null || !current.isAuthenticated) return;

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/driver/update'),
        headers: _authHeaders(current.token!),
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

  Future<void> setDriver(DriverModel? driver, String? token) async {
    if (driver == null || token == null) {
      return logout();
    }

    await _storage.write(key: 'token', value: token);
    await _storage.write(key: 'driver', value: jsonEncode(driver.toJson()));
    await _storage.write(key: 'isOnline', value: driver.isOnline.toString());

    if (driver.isOnline) {
      _startRealtimeUpdates(driver.id, token);
    }
    state = AsyncData(
      DriverState(driver: driver, token: token, isOnline: driver.isOnline),
    );
  }

  Future<void> logout() async {
    _stopRealtimeUpdates();
    _rejectedRideIds.clear();
    await _storage.deleteAll();
    state = const AsyncData(DriverState());
  }

  Map<String, String> _authHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };
}

final driverProvider = AsyncNotifierProvider<DriverNotifier, DriverState?>(
  () => DriverNotifier(),
);
