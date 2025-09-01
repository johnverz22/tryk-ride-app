import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import '../../business/entities/ride_entity.dart';
import '../../business/entities/driver_entity.dart';
import '../../business/usecases/request_ride_usecase.dart';
import '../../business/usecases/track_ride_usecase.dart';
import '../../business/usecases/get_nearby_drivers_usecase.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/message_queue_service.dart';

enum BookingState {
  initial,
  loadingDrivers,
  driversLoaded,
  requestingRide,
  rideRequested,
  waitingForDriver,
  driverAccepted,
  driverEnRoute,
  driverArrived,
  rideInProgress,
  rideCompleted,
  rideCancelled,
  error,
}

class RideBookingViewModel extends ChangeNotifier {
  final RequestRideUseCase _requestRideUseCase;
  final TrackRideUseCase _trackRideUseCase;
  final GetNearbyDriversUseCase _getNearbyDriversUseCase;
  final MessageQueueService? _messageQueue;

  RideBookingViewModel({
    required RequestRideUseCase requestRideUseCase,
    required TrackRideUseCase trackRideUseCase,
    required GetNearbyDriversUseCase getNearbyDriversUseCase,
    MessageQueueService? messageQueue,
  })  : _requestRideUseCase = requestRideUseCase,
        _trackRideUseCase = trackRideUseCase,
        _getNearbyDriversUseCase = getNearbyDriversUseCase,
        _messageQueue = messageQueue {
    _initializeMessageQueue();
  }

  // State
  BookingState _state = BookingState.initial;
  List<DriverEntity> _nearbyDrivers = [];
  RideEntity? _currentRide;
  DriverEntity? _assignedDriver;
  String? _errorMessage;
  RideType _selectedRideType = RideType.economy;
  
  // Location data
  String? _pickupAddress;
  double? _pickupLatitude;
  double? _pickupLongitude;
  String? _dropoffAddress;
  double? _dropoffLatitude;
  double? _dropoffLongitude;

  // Real-time tracking
  StreamSubscription<RideEntity>? _rideTrackingSubscription;
  StreamSubscription<Map<String, dynamic>>? _messageQueueSubscription;
  Timer? _driverLocationTimer;

  // Getters
  BookingState get state => _state;
  List<DriverEntity> get nearbyDrivers => _nearbyDrivers;
  RideEntity? get currentRide => _currentRide;
  DriverEntity? get assignedDriver => _assignedDriver;
  String? get errorMessage => _errorMessage;
  RideType get selectedRideType => _selectedRideType;
  
  bool get isLoading => _state == BookingState.loadingDrivers || 
                       _state == BookingState.requestingRide;
  bool get hasActiveRide => _currentRide != null && 
                           _currentRide!.status != RideStatus.completed &&
                           _currentRide!.status != RideStatus.cancelled;

  // Location getters
  String? get pickupAddress => _pickupAddress;
  String? get dropoffAddress => _dropoffAddress;
  bool get hasValidLocations => _pickupLatitude != null && 
                               _pickupLongitude != null &&
                               _dropoffLatitude != null && 
                               _dropoffLongitude != null;

  // Private methods
  void _setState(BookingState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _setState(BookingState.error);
  }

  void _clearError() {
    _errorMessage = null;
  }

  // Initialize message queue for real-time updates
  void _initializeMessageQueue() {
    if (_messageQueue == null) return;
    
    _messageQueue!.connect().then((_) {
      _messageQueueSubscription = _messageQueue!.messageStream.listen(
        _handleMessageQueueEvent,
        onError: (error) {
          debugPrint('[RideBookingViewModel] Message queue error: $error');
        },
      );
    });
  }

  void _handleMessageQueueEvent(Map<String, dynamic> event) {
    final eventType = event['type'] as String?;
    final rideId = event['ride_id'] as String?;
    
    // Only handle events for current ride
    if (rideId != _currentRide?.id) return;
    
    switch (eventType) {
      case 'ride.driver_assigned':
        _handleDriverAssigned(event);
        break;
      case 'ride.driver_location_update':
        _handleDriverLocationUpdate(event);
        break;
      case 'ride.status_changed':
        _handleRideStatusChanged(event);
        break;
      case 'ride.cancelled':
        _handleRideCancelled(event);
        break;
    }
  }

  void _handleDriverAssigned(Map<String, dynamic> event) {
    final driverData = event['driver'] as Map<String, dynamic>?;
    if (driverData != null) {
      // Update assigned driver info
      _assignedDriver = DriverEntity(
        id: driverData['id'],
        name: driverData['name'],
        phone: driverData['phone'],
        rating: (driverData['rating'] as num?)?.toDouble() ?? 5.0,
        totalTrips: driverData['total_trips'] ?? 0,
        status: DriverStatus.online,
        vehicleType: driverData['vehicle_type'],
        licensePlate: driverData['license_plate'],
      );
      
      _setState(BookingState.driverAccepted);
    }
  }

  void _handleDriverLocationUpdate(Map<String, dynamic> event) {
    final latitude = (event['latitude'] as num?)?.toDouble();
    final longitude = (event['longitude'] as num?)?.toDouble();
    final eta = event['eta_minutes'] as int?;
    
    if (latitude != null && longitude != null && _currentRide != null) {
      _currentRide = _currentRide!.copyWith(
        currentDriverLatitude: latitude,
        currentDriverLongitude: longitude,
        estimatedArrivalMinutes: eta,
      );
      notifyListeners();
    }
  }

  void _handleRideStatusChanged(Map<String, dynamic> event) {
    final statusString = event['status'] as String?;
    if (statusString != null && _currentRide != null) {
      final status = _parseRideStatus(statusString);
      _currentRide = _currentRide!.copyWith(status: status);
      _updateStateBasedOnRideStatus(status);
    }
  }

  void _handleRideCancelled(Map<String, dynamic> event) {
    final reason = event['reason'] as String?;
    _setError('Ride cancelled: ${reason ?? 'Unknown reason'}');
    _setState(BookingState.rideCancelled);
  }

  RideStatus _parseRideStatus(String statusString) {
    switch (statusString.toLowerCase()) {
      case 'requested': return RideStatus.requested;
      case 'accepted': return RideStatus.accepted;
      case 'driver_en_route': return RideStatus.driverEnRoute;
      case 'arrived': return RideStatus.arrived;
      case 'in_progress': return RideStatus.inProgress;
      case 'completed': return RideStatus.completed;
      case 'cancelled': return RideStatus.cancelled;
      default: return RideStatus.requested;
    }
  }

  // Public methods
  void setRideType(RideType rideType) {
    _selectedRideType = rideType;
    notifyListeners();
  }

  void setPickupLocation({
    required String address,
    required double latitude,
    required double longitude,
  }) {
    _pickupAddress = address;
    _pickupLatitude = latitude;
    _pickupLongitude = longitude;
    notifyListeners();
  }

  void setDropoffLocation({
    required String address,
    required double latitude,
    required double longitude,
  }) {
    _dropoffAddress = address;
    _dropoffLatitude = latitude;
    _dropoffLongitude = longitude;
    notifyListeners();
  }

  Future<void> loadNearbyDrivers() async {
    if (!hasValidLocations) {
      _setError('Please set pickup and dropoff locations first');
      return;
    }

    _setState(BookingState.loadingDrivers);
    _clearError();

    final result = await _getNearbyDriversUseCase.call(
      GetNearbyDriversParams(
        latitude: _pickupLatitude!,
        longitude: _pickupLongitude!,
        rideType: _selectedRideType,
      ),
    );

    result.fold(
      (failure) => _setError(_mapFailureToMessage(failure)),
      (drivers) {
        _nearbyDrivers = drivers;
        _setState(BookingState.driversLoaded);
      },
    );
  }

  Future<void> requestRide({String? paymentMethod}) async {
    if (!hasValidLocations) {
      _setError('Please set pickup and dropoff locations first');
      return;
    }

    _setState(BookingState.requestingRide);
    _clearError();

    final result = await _requestRideUseCase.call(
      RequestRideParams(
        rideType: _selectedRideType,
        pickupAddress: _pickupAddress!,
        pickupLatitude: _pickupLatitude!,
        pickupLongitude: _pickupLongitude!,
        dropoffAddress: _dropoffAddress!,
        dropoffLatitude: _dropoffLatitude!,
        dropoffLongitude: _dropoffLongitude!,
        paymentMethod: paymentMethod,
      ),
    );

    result.fold(
      (failure) => _setError(_mapFailureToMessage(failure)),
      (ride) {
        _currentRide = ride;
        _setState(BookingState.rideRequested);
        _startRideTracking(ride.id);
        
        // Subscribe to ride-specific message queue events
        _messageQueue?.subscribe('ride.${ride.id}');
        
        // Publish ride request event for analytics/monitoring
        _messageQueue?.publish('ride.requested', {
          'ride_id': ride.id,
          'user_id': ride.userId,
          'ride_type': ride.type.toString(),
          'pickup_location': {
            'latitude': ride.pickupLatitude,
            'longitude': ride.pickupLongitude,
          },
          'timestamp': DateTime.now().toIso8601String(),
        });
      },
    );
  }

  void _startRideTracking(String rideId) {
    _rideTrackingSubscription?.cancel();
    _rideTrackingSubscription = _trackRideUseCase.call(rideId).listen(
      (ride) {
        _currentRide = ride;
        _updateStateBasedOnRideStatus(ride.status);
        notifyListeners();
      },
      onError: (error) {
        _setError('Failed to track ride: $error');
      },
    );
  }

  void _updateStateBasedOnRideStatus(RideStatus status) {
    switch (status) {
      case RideStatus.requested:
        _setState(BookingState.waitingForDriver);
        break;
      case RideStatus.accepted:
        _setState(BookingState.driverAccepted);
        break;
      case RideStatus.driverEnRoute:
        _setState(BookingState.driverEnRoute);
        break;
      case RideStatus.arrived:
        _setState(BookingState.driverArrived);
        break;
      case RideStatus.inProgress:
        _setState(BookingState.rideInProgress);
        break;
      case RideStatus.completed:
        _setState(BookingState.rideCompleted);
        _stopTracking();
        break;
      case RideStatus.cancelled:
        _setState(BookingState.rideCancelled);
        _stopTracking();
        break;
    }
  }

  void _stopTracking() {
    _rideTrackingSubscription?.cancel();
    _driverLocationTimer?.cancel();
    
    // Unsubscribe from ride-specific events
    if (_currentRide != null) {
      _messageQueue?.unsubscribe('ride.${_currentRide!.id}');
    }
  }

  void resetBooking() {
    _stopTracking();
    _currentRide = null;
    _assignedDriver = null;
    _nearbyDrivers.clear();
    _errorMessage = null;
    _setState(BookingState.initial);
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Server error occurred. Please try again.';
      case NetworkFailure:
        return 'Network connection failed. Check your internet.';
      case AuthFailure:
        return 'Authentication failed. Please login again.';
      default:
        return 'An unexpected error occurred.';
    }
  }

  @override
  void dispose() {
    _stopTracking();
    _messageQueueSubscription?.cancel();
    _messageQueue?.disconnect();
    super.dispose();
  }
}