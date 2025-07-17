import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:user/features/core/errors/failures.dart';
import 'package:user/features/ride/presentation/providers/ride_booking_provider.dart';
import 'package:user/features/ride/presentation/screens/ride_tracking_screen.dart';
import 'package:user/features/profile/presentation/providers/payment_info_provider.dart';
import 'package:user/features/profile/presentation/widgets/widgets.dart'; // Assuming this imports PaymentMethodCard

import 'package:user/core/utils/geo_utils.dart'; // Assuming calculateDistanceKm is here
import 'package:user/features/ride/domain/entities/ride.dart'; // Assuming Ride entity is here
import 'package:user/features/ride/presentation/widgets/ride_booking_screen/widgets.dart'; // Assuming this imports LocationSelector, RoutePreviewSection, RouteInfoCard, DriverSearchRadiusSlider, SearchingDriverBottomSheet

class RideBookingScreen extends ConsumerStatefulWidget {
  const RideBookingScreen({super.key});

  @override
  ConsumerState<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends ConsumerState<RideBookingScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  LatLng? _fromLocation;
  LatLng? _toLocation;
  String _selectedPaymentMethod = 'Cash';
  double _searchRadiusKm = 10;
  bool _isLoading = false;

  double? _distance;
  double? _duration;
  double? _fare;

  static const double _baseFare = 5.0;
  static const double _perKmRate = 2.0;

  @override
  void initState() {
    super.initState();
    _ensureLocationPermission();
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _handleRouteInfoLoaded(double distanceKm, double durationMinutes) {
    final double fare = _baseFare + (_perKmRate * distanceKm);

    setState(() {
      _distance = distanceKm;
      _duration = durationMinutes;
      _fare = fare;
    });
    debugPrint(
      'Route info loaded: Distance: $distanceKm km, Duration: $durationMinutes min, Fare: \$$fare',
    );
  }

  Future<void> _ensureLocationPermission() async {
    if (await Permission.location.request().isGranted) return;
    await openAppSettings();
  }

  Future<void> _fetchRouteInfo() async {
    if (_fromLocation == null || _toLocation == null) {
      debugPrint('Cannot fetch route info: From or To location is null.');
      setState(() {
        _distance = null;
        _duration = null;
        _fare = null;
      });
      return;
    }

    // Simulate API call for distance and duration
    // In a real app, you'd use a mapping service API (e.g., Google Maps Directions API)
    final distance = calculateDistanceKm(
      _fromLocation!.latitude,
      _fromLocation!.longitude,
      _toLocation!.latitude,
      _toLocation!.longitude,
    );
    // Assuming average speed of 40 km/h to estimate duration
    final duration = distance / 40 * 60; // duration in minutes
    final fare = _baseFare + (_perKmRate * distance);

    setState(() {
      _distance = distance;
      _duration = duration;
      _fare = fare;
    });
    debugPrint(
      'Calculated route info: Distance: $distance km, Duration: $duration min, Fare: \$$fare',
    );
  }

  Future<void> _showDriverConfirmedModal({
    required int rideId,
    required String driverName,
    String? profilePicture,
    required String vehicle,
  }) async {
    if (!mounted) return;

    final confirmed = await showModalBottomSheet<bool?>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (bottomSheetContext) {
        return PopScope(
          canPop: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.emoji_transportation,
                  size: 48,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Driver Confirmed!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$driverName is on the way to pick you up!',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundImage: (profilePicture?.isNotEmpty ?? false)
                          ? NetworkImage(profilePicture!)
                          : null,
                      backgroundColor: Colors.grey[300],
                      child: (profilePicture == null || profilePicture.isEmpty)
                          ? const Icon(
                              Icons.person,
                              size: 36,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driverName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 16),
                              SizedBox(width: 4),
                              Text('4.8'), // Placeholder for driver rating
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Vehicle: $vehicle',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.track_changes),
                    label: const Text('Track Ride'),
                    onPressed: () {
                      Navigator.of(
                        bottomSheetContext,
                        rootNavigator: true,
                      ).pop(true);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RideTrackingScreen(rideId: rideId)),
      );
    }
  }

  Future<void> _handlePayment() async {
    if (_fromLocation == null || _toLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select pickup and dropoff locations.'),
        ),
      );
      return;
    }
    if (_distance == null || _duration == null || _fare == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for route information to load.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Show loading indicator on UI
    });

    final rideRequest = Ride(
      pickupAddress: _fromController.text,
      pickupLatitude: _fromLocation!.latitude,
      pickupLongitude: _fromLocation!.longitude,
      dropoffAddress: _toController.text,
      dropoffLatitude: _toLocation!.latitude,
      dropoffLongitude: _toLocation!.longitude,
      requestedAt: DateTime.now(),
      distanceKm: double.parse(_distance!.toStringAsFixed(2)),
      durationMinutes: double.parse(_duration!.toStringAsFixed(2)),
      fareAmount: _fare!,
      paymentMethod: _selectedPaymentMethod,
      searchRadiusKm: _searchRadiusKm.round(),
    );

    final requestRideUseCase = ref.read(requestRideUseCaseProvider);

    final result = await requestRideUseCase(rideRequest);

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false; // Hide loading indicator
        });

        String errorMessage;
        if (failure is ServerFailure) {
          errorMessage = failure.message;
        } else if (failure is NoInternetFailure) {
          errorMessage = 'No internet connection. Please check your network.';
        } else if (failure is UnexpectedFailure) {
          errorMessage = failure.message;
        } else if (failure is UnauthorizedFailure) {
          errorMessage = 'Authentication failed. Please log in again.';
        } else {
          errorMessage = 'An unknown error occurred. Please try again.';
        }

        debugPrint('Ride request failed: $errorMessage');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      },
      (rideId) async {
        setState(() {
          _isLoading =
              false; // Hide loading indicator, as bottom sheet will show its own
        });

        debugPrint('Ride requested successfully with ID: $rideId');

        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (bottomSheetContext) {
            return SearchingDriverBottomSheet(
              rideId: rideId, // Pass the extracted int rideId
              onDriverConfirmed: (driverInfo) {
                if (mounted) {
                  _showDriverConfirmedModal(
                    rideId: driverInfo.rideId,
                    driverName: driverInfo.driverName,
                    profilePicture: driverInfo.profilePicture,
                    vehicle: driverInfo.vehicle,
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(paymentInfoProvider);
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    final canRequestRide =
        _fromLocation != null && _toLocation != null && !_isLoading;
    final bool showRouteInfo = _fromLocation != null && _toLocation != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Ride'),
        backgroundColor: color.primary,
        foregroundColor: color.onPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Input Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.route, color: color.primary),
                        const SizedBox(width: 10),
                        Text(
                          'Plan Your Trip',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LocationSelector(
                      label: 'Pickup Location',
                      icon: Icons.my_location,
                      controller: _fromController,
                      onLocationPicked: (picked) async {
                        final loc = picked['latLng'] as LatLng?;
                        final desc = picked['description'] as String?;
                        setState(() {
                          _fromLocation = loc;
                          _fromController.text = desc ?? '';
                        });
                        debugPrint('Pickup location picked: $_fromLocation');
                        await _fetchRouteInfo();
                      },
                      onClear: () => setState(() {
                        _fromController.clear();
                        _fromLocation = null;
                        _distance = null; // Clear route info on clear
                        _duration = null;
                        _fare = null;
                        debugPrint('Pickup location cleared.');
                      }),
                    ),
                    const SizedBox(height: 16),
                    LocationSelector(
                      label: 'Destination',
                      icon: Icons.location_on,
                      controller: _toController,
                      onLocationPicked: (picked) async {
                        final loc = picked['latLng'] as LatLng?;
                        final desc = picked['description'] as String?;
                        setState(() {
                          _toLocation = loc;
                          _toController.text = desc ?? '';
                        });
                        debugPrint('Destination location picked: $_toLocation');
                        await _fetchRouteInfo();
                      },
                      onClear: () => setState(() {
                        _toController.clear();
                        _toLocation = null;
                        _distance = null; // Clear route info on clear
                        _duration = null;
                        _fare = null;
                        debugPrint('Destination location cleared.');
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// Payment Method
              walletAsync.when(
                data: (paymentInfo) => PaymentMethodCard(
                  selectedMethod: _selectedPaymentMethod,
                  onSelect: (method) =>
                      setState(() => _selectedPaymentMethod = method),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) =>
                    const Center(child: Text('Failed to load wallet')),
              ),

              const SizedBox(height: 20),

              /// Route Preview & Info (Animated)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: showRouteInfo
                    ? Column(
                        key: const ValueKey(
                          'route_info_visible',
                        ), // Key when visible
                        children: [
                          RoutePreviewSection(
                            from: _fromLocation!,
                            to: _toLocation!,
                            onRouteInfoLoaded: _handleRouteInfoLoaded,
                          ),
                          const SizedBox(height: 20),
                          if (_distance != null &&
                              _duration != null &&
                              _fare != null)
                            RouteInfoCard(
                              distanceInMeters: _distance! * 1000,
                              duration: _duration!,
                              fare: _fare!,
                            ),
                        ],
                      )
                    : const SizedBox.shrink(
                        key: ValueKey('route_info_hidden'),
                      ), // Key when hidden
              ),

              const SizedBox(height: 20),

              /// Search Radius
              DriverSearchRadiusSlider(
                radiusKm: _searchRadiusKm,
                onChanged: (value) => setState(() => _searchRadiusKm = value),
              ),

              const SizedBox(height: 20),

              /// Request Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: canRequestRide ? _handlePayment : null,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.local_taxi),
                  label: Text(_isLoading ? 'Requesting...' : 'Request Ride'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: color.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
