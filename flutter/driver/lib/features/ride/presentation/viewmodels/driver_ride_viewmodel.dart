import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../driver/business/entities/driver_entity.dart';
import '../../business/entities/ride_request_entity.dart';

enum DriverRideState {
  offline,
  online,
  receivingRequest,
  acceptingRequest,
  enRouteToPickup,
  arrivedAtPickup,
  rideInProgress,
  completingRide,
  error,
}

class DriverRideViewModel extends ChangeNotifier {
  // State
  DriverRideState _state = DriverRideState.offline;
  List<RideRequestEntity> _pendingRequests = [];
  RideRequestEntity? _currentRequest;
  String? _errorMessage;
  bool _isOnline = false;
  
  // Location tracking
  double? _currentLatitude;
  double? _currentLongitude;
  
  // Timers and streams
  Timer? _requestExpirationTimer;
  StreamSubscription? _locationSubscription;
  StreamSubscription? _rideRequestsSubscription;

  // Getters
  DriverRideState get state => _state;
  List<RideRequestEntity> get pendingRequests => _pendingRequests;
  RideRequestEntity? get currentRequest => _currentRequest;
  String? get errorMessage => _errorMessage;
  bool get isOnline => _isOnline;
  bool get hasActiveRide => _currentRequest != null;
  
  double? get currentLatitude => _currentLatitude;
  double? get currentLongitude => _currentLongitude;

  // Private methods
  void _setState(DriverRideState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _setState(DriverRideState.error);
  }

  void _clearError() {
    _errorMessage = null;
  }

  // Public methods
  Future<void> goOnline() async {
    try {
      _clearError();
      _isOnline = true;
      _setState(DriverRideState.online);
      
      // Start listening for ride requests
      _startListeningForRequests();
      
      // Start location tracking
      _startLocationTracking();
      
      debugPrint('[DriverRideViewModel] Driver is now online');
    } catch (e) {
      _setError('Failed to go online: $e');
    }
  }

  Future<void> goOffline() async {
    try {
      _isOnline = false;
      _setState(DriverRideState.offline);
      
      // Stop all subscriptions
      _stopListeningForRequests();
      _stopLocationTracking();
      
      // Clear current data
      _pendingRequests.clear();
      _currentRequest = null;
      
      debugPrint('[DriverRideViewModel] Driver is now offline');
      notifyListeners();
    } catch (e) {
      _setError('Failed to go offline: $e');
    }
  }

  void _startListeningForRequests() {
    // Simulate receiving ride requests
    _rideRequestsSubscription = Stream.periodic(
      const Duration(seconds: 10),
      (count) => _generateMockRideRequest(),
    ).listen(
      (request) {
        if (_isOnline && _state == DriverRideState.online) {
          _addNewRequest(request);
        }
      },
    );
  }

  void _stopListeningForRequests() {
    _rideRequestsSubscription?.cancel();
    _requestExpirationTimer?.cancel();
  }

  void _startLocationTracking() {
    // Simulate location updates
    _locationSubscription = Stream.periodic(
      const Duration(seconds: 5),
      (count) => {
        'latitude': 37.7749 + (count * 0.001), // Mock movement
        'longitude': -122.4194 + (count * 0.001),
      },
    ).listen(
      (location) {
        _currentLatitude = location['latitude'];
        _currentLongitude = location['longitude'];
        notifyListeners();
      },
    );
  }

  void _stopLocationTracking() {
    _locationSubscription?.cancel();
  }

  void _addNewRequest(RideRequestEntity request) {
    _pendingRequests.add(request);
    _setState(DriverRideState.receivingRequest);
    
    // Auto-expire request after timeout
    _requestExpirationTimer = Timer(
      request.timeRemaining,
      () => _expireRequest(request.id),
    );
    
    debugPrint('[DriverRideViewModel] New ride request received: ${request.id}');
  }

  void _expireRequest(String requestId) {
    _pendingRequests.removeWhere((r) => r.id == requestId);
    
    if (_pendingRequests.isEmpty && _state == DriverRideState.receivingRequest) {
      _setState(DriverRideState.online);
    }
    
    notifyListeners();
  }

  Future<void> acceptRequest(String requestId) async {
    try {
      _setState(DriverRideState.acceptingRequest);
      _clearError();
      
      final request = _pendingRequests.firstWhere((r) => r.id == requestId);
      
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Remove from pending and set as current
      _pendingRequests.removeWhere((r) => r.id == requestId);
      _currentRequest = request.copyWith(status: RideRequestStatus.accepted);
      
      _setState(DriverRideState.enRouteToPickup);
      
      debugPrint('[DriverRideViewModel] Accepted ride request: $requestId');
    } catch (e) {
      _setError('Failed to accept request: $e');
    }
  }

  Future<void> declineRequest(String requestId) async {
    try {
      _pendingRequests.removeWhere((r) => r.id == requestId);
      
      if (_pendingRequests.isEmpty) {
        _setState(DriverRideState.online);
      }
      
      debugPrint('[DriverRideViewModel] Declined ride request: $requestId');
      notifyListeners();
    } catch (e) {
      _setError('Failed to decline request: $e');
    }
  }

  Future<void> arriveAtPickup() async {
    if (_currentRequest == null) return;
    
    try {
      _setState(DriverRideState.arrivedAtPickup);
      debugPrint('[DriverRideViewModel] Arrived at pickup location');
    } catch (e) {
      _setError('Failed to update arrival status: $e');
    }
  }

  Future<void> startRide() async {
    if (_currentRequest == null) return;
    
    try {
      _setState(DriverRideState.rideInProgress);
      debugPrint('[DriverRideViewModel] Ride started');
    } catch (e) {
      _setError('Failed to start ride: $e');
    }
  }

  Future<void> completeRide() async {
    if (_currentRequest == null) return;
    
    try {
      _setState(DriverRideState.completingRide);
      
      // Simulate completion delay
      await Future.delayed(const Duration(seconds: 2));
      
      _currentRequest = null;
      _setState(DriverRideState.online);
      
      debugPrint('[DriverRideViewModel] Ride completed');
    } catch (e) {
      _setError('Failed to complete ride: $e');
    }
  }

  // Mock data generator
  RideRequestEntity _generateMockRideRequest() {
    final now = DateTime.now();
    final requestId = 'req_${now.millisecondsSinceEpoch}';
    
    return RideRequestEntity(
      id: requestId,
      userId: 'user_123',
      userName: 'John Doe',
      userRating: 4.8,
      pickupAddress: '123 Main St, San Francisco, CA',
      pickupLatitude: 37.7749,
      pickupLongitude: -122.4194,
      dropoffAddress: '456 Market St, San Francisco, CA',
      dropoffLatitude: 37.7849,
      dropoffLongitude: -122.4094,
      rideType: 'Economy',
      fareAmount: 12.50,
      distanceKm: 5.2,
      estimatedDurationMinutes: 15,
      requestedAt: now,
      expiresAt: now.add(const Duration(seconds: 30)),
      status: RideRequestStatus.pending,
      distanceFromDriver: 0.8,
    );
  }

  @override
  void dispose() {
    _stopListeningForRequests();
    _stopLocationTracking();
    super.dispose();
  }
}