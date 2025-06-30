import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:user/features/user/presentation/pages/screens/navigation/home/ride_tracking_screen.dart';
import '../../../../../../../core/services/auth_service.dart';
import '../../../../widgets/widgets.dart';

class RideBookingScreen extends StatefulWidget {
  const RideBookingScreen({super.key});

  @override
  State<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends State<RideBookingScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  String? baseUrl = dotenv.env['BASE_URL'];
  String? googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
  LatLng? _fromLocation;
  LatLng? _toLocation;
  String _selectedPaymentMethod = 'Cash';
  double _searchRadiusKm = 10;
  bool _isLoading = false;
  bool _rideCancelled = false;
  bool _isBottomSheetOpen = false;
  Timer? _statusCheckTimer;

  double? _routeDistanceMeters;
  int? _routeDurationSeconds;
  final double _baseFare = 5.0;
  final double _perKmRate = 2.0;
  final double _averageSpeedKmh = 40.0;
  int? _rideId;
  static const int requestedStatusId = 1;

  @override
  void initState() {
    super.initState();
    _ensureLocationPermission();
  }

  Future<void> _ensureLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required.')),
        );
      }
    }
  }

  Future<void> _fetchRouteInfo() async {
    if (_fromLocation == null ||
        _toLocation == null ||
        googleMapsApiKey == null)
      return;

    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${_fromLocation!.latitude},${_fromLocation!.longitude}&destination=${_toLocation!.latitude},${_toLocation!.longitude}&key=$googleMapsApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final leg = data['routes'][0]['legs'][0];
          setState(() {
            _routeDistanceMeters = (leg['distance']['value'] as num).toDouble();
            _routeDurationSeconds = (leg['duration']['value'] as num).toInt();
          });
        }
      }
    } catch (e) {
      // Optionally handle error
    }
  }

  // Replace your entire _checkRideStatusPeriodically method with this fixed version
  Future<void> _checkRideStatusPeriodically() async {
    final token = await AuthService().getToken();
    if (token == null || _rideId == null) return;

    _statusCheckTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      try {
        final uri = Uri.parse('$baseUrl/rides/$_rideId');
        final response = await http.get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final ride = data['ride'];
          final statusId = ride['ride_status_id'];

          if (statusId == 2 && ride['driver'] != null) {
            // Cancel timer FIRST before any UI operations
            timer.cancel();
            _statusCheckTimer = null;

            // Close any existing bottom sheet
            if (_isBottomSheetOpen && mounted) {
              Navigator.of(context, rootNavigator: true).pop();
              _isBottomSheetOpen = false;
              await Future.delayed(const Duration(milliseconds: 300));
            }

            if (mounted) {
              final driver = ride['driver'];
              final profilePicture = driver['profile_picture'];
              final vehicle = driver['vehicle'] ?? 'Toyota Vios';
              final driverName = driver['name'];

              // Show driver confirmed modal and handle navigation
              await _showDriverConfirmedModal(
                driverName,
                profilePicture,
                vehicle,
              );
            }
          }
        }
      } catch (e) {
        print('Error polling ride status: $e');
      }
    });
  }

  // New separate method to handle the driver confirmed modal
  Future<void> _showDriverConfirmedModal(
    String driverName,
    String? profilePicture,
    String vehicle,
  ) async {
    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      isDismissible: false, // Prevent dismissing by tapping outside
      enableDrag: false, // Prevent dismissing by dragging
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (bottomSheetContext) {
        return WillPopScope(
          onWillPop: () async => false, // Prevent back button dismissal
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
                      backgroundImage:
                          profilePicture != null && profilePicture.isNotEmpty
                          ? NetworkImage(profilePicture)
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
                              Text('4.8'),
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
                    icon: const Icon(Icons.verified),
                    label: const Text('Great, thanks!'),
                    onPressed: () {
                      Navigator.of(
                        bottomSheetContext,
                      ).pop('navigate_to_tracking');
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

    if (!mounted) return;

    print('Driver confirmed modal result: $result');

    // Handle navigation after modal closes
    if (result == 'navigate_to_tracking' && mounted) {
      print(
        '[NAVIGATION] About to navigate to TrackDriverScreen with rideId: $_rideId',
      );

      try {
        // Navigate to tracking screen
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) {
              print('[NAVIGATION] Building TrackDriverScreen');
              return RideTrackingScreen(
                rideId: _rideId,
                pickup: _fromLocation,
                destination: _toLocation,
              );
            },
          ),
        );
        print('[NAVIGATION] Navigation completed successfully');
      } catch (e) {
        print('[NAVIGATION] Navigation failed: $e');
      }
    } else {
      print(
        '[NAVIGATION] Navigation skipped - result: $result, mounted: $mounted',
      );
    }
  }

  // Also update your _showSearchingBottomSheet method to handle cancellation properly
  Future<void> _showSearchingBottomSheet() async {
    _isBottomSheetOpen = true;
    setState(() => _rideCancelled = false);
    final controller = DraggableScrollableController();
    String statusText = 'Looking for a nearby driver...';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder:
              (
                BuildContext sheetContext,
                void Function(VoidCallback) setSheetState,
              ) {
                Future.delayed(const Duration(seconds: 5), () {
                  if (!sheetContext.mounted || _rideCancelled) return;

                  setSheetState(() {
                    statusText = 'Matching you with the best driver...';
                  });
                });

                return DraggableScrollableSheet(
                  controller: controller,
                  initialChildSize: 0.3,
                  minChildSize: 0.3,
                  maxChildSize: 0.5,
                  builder:
                      (
                        BuildContext context,
                        ScrollController scrollController,
                      ) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 12,
                                offset: const Offset(0, -3),
                              ),
                            ],
                          ),
                          child: ListView(
                            controller: scrollController,
                            children: [
                              const Center(child: CircularProgressIndicator()),
                              const SizedBox(height: 20),
                              Center(
                                child: Text(
                                  statusText,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Center(
                                child: Text(
                                  'Hang tight! A driver will be assigned shortly.',
                                  style: TextStyle(fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Center(
                                child: TextButton.icon(
                                  onPressed: () async {
                                    setState(() => _rideCancelled = true);
                                    setSheetState(
                                      () => statusText = 'Cancelling ride...',
                                    );

                                    // Cancel the ride
                                    final token = await AuthService()
                                        .getToken();
                                    if (token != null && _rideId != null) {
                                      final uri = Uri.parse(
                                        '$baseUrl/rides/cancel',
                                      );
                                      await http.post(
                                        uri,
                                        headers: {
                                          'Authorization': 'Bearer $token',
                                          'Content-Type': 'application/json',
                                        },
                                        body: jsonEncode({'ride_id': _rideId}),
                                      );
                                    }

                                    // Cancel the status check timer
                                    _statusCheckTimer?.cancel();
                                    _statusCheckTimer = null;

                                    setState(() => _rideId = null);

                                    if (context.mounted) {
                                      Navigator.of(
                                        context,
                                        rootNavigator: true,
                                      ).pop();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Ride request cancelled.',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                  ),
                                  label: const Text(
                                    'Cancel Ride',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                );
              },
        );
      },
    );
    _isBottomSheetOpen = false;
  }

  // New separate method to handle the driver confirmed modal

  Future<void> _requestRide() async {
    if (_fromLocation == null || _toLocation == null) return;

    final distance = _calculateDistanceKm(
      _fromLocation!.latitude,
      _fromLocation!.longitude,
      _toLocation!.latitude,
      _toLocation!.longitude,
    );

    final double fare = _baseFare + _perKmRate * distance;
    final double durationMinutes = distance / _averageSpeedKmh * 60;
    final now = DateTime.now().toIso8601String();

    final uri = Uri.parse('$baseUrl/rides/request');
    final token = await AuthService().getToken();

    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You must be logged in.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'pickup_address': _fromController.text,
          'pickup_latitude': _fromLocation!.latitude,
          'pickup_longitude': _fromLocation!.longitude,
          'dropoff_address': _toController.text,
          'dropoff_latitude': _toLocation!.latitude,
          'dropoff_longitude': _toLocation!.longitude,
          'requested_at': now,
          'distance_km': distance,
          'duration_minutes': durationMinutes,
          'fare_amount': fare,
          'ride_status_id': requestedStatusId,
          'payment_method': _selectedPaymentMethod,
          'search_radius_km': _searchRadiusKm.round(),
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _rideId = responseData['ride']['id'];
        });

        _checkRideStatusPeriodically();
        await _showSearchingBottomSheet();

        if (mounted && !_rideCancelled) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      } else {
        final error = jsonDecode(response.body)['message'] ?? response.body;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Request failed: $error')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371;
    final double dLat = _degToRad(lat2 - lat1);
    final double dLon = _degToRad(lon2 - lon1);

    final double a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * pi / 180;

  double _getEstimatedCost(double km) => _baseFare + (_perKmRate * km);
  double _getEstimatedTimeInMinutes(double km) => km / _averageSpeedKmh * 60;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    final bool hasRouteInfo =
        _routeDistanceMeters != null && _routeDurationSeconds != null;
    final double? totalDistance = hasRouteInfo
        ? _routeDistanceMeters! / 1000
        : (_fromLocation != null && _toLocation != null)
        ? _calculateDistanceKm(
            _fromLocation!.latitude,
            _fromLocation!.longitude,
            _toLocation!.latitude,
            _toLocation!.longitude,
          )
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Ride'),
        backgroundColor: color.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plan Your Trip',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            LocationInputCard(
              label: 'Pickup Location',
              icon: Icons.my_location,
              controller: _fromController,
              onLocationPicked: (picked) async {
                final LatLng loc = picked['latLng'];
                final String desc = picked['description'];
                setState(() {
                  _fromLocation = loc;
                  _fromController.text = desc;
                  _routeDistanceMeters = null;
                  _routeDurationSeconds = null;
                });
                await _fetchRouteInfo();
              },
              onClear: () {
                setState(() {
                  _fromController.clear();
                  _fromLocation = null;
                });
              },
            ),
            const SizedBox(height: 16),
            LocationInputCard(
              label: 'Destination',
              icon: Icons.location_on,
              controller: _toController,
              onLocationPicked: (picked) async {
                final LatLng loc = picked['latLng'];
                final String desc = picked['description'];
                setState(() {
                  _toLocation = loc;
                  _toController.text = desc;
                  _routeDistanceMeters = null;
                  _routeDurationSeconds = null;
                });
                await _fetchRouteInfo();
              },
              onClear: () {
                setState(() {
                  _toController.clear();
                  _toLocation = null;
                });
              },
            ),
            // Payment Method Section - Consistent Card Style
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.payment, color: color.primary, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Payment Method',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _simplePaymentOption(
                          icon: Icons.money,
                          label: 'Cash',
                          selected: _selectedPaymentMethod == 'Cash',
                          onTap: () =>
                              setState(() => _selectedPaymentMethod = 'Cash'),
                        ),
                        _simplePaymentOption(
                          icon: Icons.credit_card,
                          label: 'Card',
                          selected: _selectedPaymentMethod == 'Card',
                          onTap: () =>
                              setState(() => _selectedPaymentMethod = 'Card'),
                        ),
                        _simplePaymentOption(
                          icon: Icons.account_balance_wallet,
                          label: 'Wallet',
                          selected: _selectedPaymentMethod == 'Wallet',
                          onTap: () =>
                              setState(() => _selectedPaymentMethod = 'Wallet'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_fromLocation != null &&
                _toLocation != null &&
                totalDistance != null) ...[
              const SizedBox(height: 32),
              Text(
                'Route Preview',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              RideMapPreview(
                key: ValueKey(
                  '${_fromLocation!.latitude},${_fromLocation!.longitude}-${_toLocation!.latitude},${_toLocation!.longitude}',
                ),
                fromLocation: _fromLocation!,
                toLocation: _toLocation!,
                apiKey: googleMapsApiKey,
              ),
              const SizedBox(height: 12),
              RouteInfoCard(
                cost: _getEstimatedCost(totalDistance).toStringAsFixed(2),
                distanceInMeters: hasRouteInfo
                    ? _routeDistanceMeters!
                    : totalDistance * 1000,
                duration: hasRouteInfo
                    ? (_routeDurationSeconds! / 60).toStringAsFixed(2)
                    : _getEstimatedTimeInMinutes(
                        totalDistance,
                      ).toStringAsFixed(2),
              ),
            ],
            const SizedBox(height: 20),
            // Modern Driver Search Radius Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.radar, color: color.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Driver Search Radius',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_searchRadiusKm.toStringAsFixed(0)} km',
                          style: TextStyle(
                            color: color.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Slider(
                    value: _searchRadiusKm,
                    min: 5,
                    max: 100,
                    divisions: 19,
                    label: _searchRadiusKm.toStringAsFixed(0),
                    activeColor: color.primary,
                    inactiveColor: Colors.grey[300],
                    onChanged: (value) =>
                        setState(() => _searchRadiusKm = value),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        '5 km',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        '100 km',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    (_fromLocation != null &&
                        _toLocation != null &&
                        !_isLoading)
                    ? _requestRide
                    : null,
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
    );
  }

  // Replace _buildPaymentOption with this simpler version:
  Widget _simplePaymentOption({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withOpacity(0.08)
                : null,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? theme.colorScheme.primary : Colors.grey[300]!,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? theme.colorScheme.primary : Colors.grey[600],
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: selected
                      ? theme.colorScheme.primary
                      : Colors.grey[700],
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }
}
