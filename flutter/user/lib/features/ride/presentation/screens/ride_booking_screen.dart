import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:user/features/ride/presentation/providers/ride_booking_provider.dart';
import 'package:user/features/ride/presentation/screens/ride_tracking_screen.dart';
import 'package:user/features/profile/presentation/providers/payment_info_provider.dart';
import 'package:user/features/profile/presentation/widgets/widgets.dart';

import 'package:user/core/utils/geo_utils.dart';
import 'package:user/features/ride/domain/entities/ride.dart';
import 'package:user/features/ride/presentation/widgets/ride_booking_screen/widgets.dart';
import 'package:dio/dio.dart';

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

  void _handleRouteInfoLoaded(double distanceKm, double durationMinutes) {
    final double fare = _baseFare + (_perKmRate * distanceKm);

    setState(() {
      _distance = distanceKm;
      _duration = durationMinutes;
      _fare = fare;
    });
  }

  Future<void> _ensureLocationPermission() async {
    if (await Permission.location.request().isGranted) return;
    await openAppSettings();
  }

  Future<void> _fetchRouteInfo() async {
    if (_fromLocation == null || _toLocation == null) return;

    final distance = calculateDistanceKm(
      _fromLocation!.latitude,
      _fromLocation!.longitude,
      _toLocation!.latitude,
      _toLocation!.longitude,
    );
    final duration = distance / 40 * 60;
    final fare = _baseFare + (_perKmRate * distance);

    setState(() {
      _distance = distance;
      _duration = duration;
      _fare = fare;
    });
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
                    label: const Text('Track Ride!'),
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
    if (_fromLocation == null || _toLocation == null) return;

    setState(() {
      _isLoading = true;
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

    final requestRide = ref.read(requestRideUseCaseProvider);

    try {
      final rideId = await requestRide(rideRequest);

      if (!mounted) return;

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (bottomSheetContext) {
          return SearchingDriverBottomSheet(
            rideId: rideId,
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
    } on DioException catch (e) {
      debugPrint('Dio Error: ${e.response?.statusCode} - ${e.message}');
      String errorMessage = 'Failed to request ride.';
      if (e.response != null && e.response!.data != null) {
        if (e.response!.data is Map &&
            e.response!.data.containsKey('message')) {
          errorMessage = e.response!.data['message'] as String;
        } else if (e.response!.data is String) {
          errorMessage = e.response!.data as String;
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        final errorMessage = e
            .toString()
            .replaceFirst('Exception: ', '')
            .trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(paymentInfoProvider);
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    final canRequestRide =
        _fromLocation != null && _toLocation != null && !_isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Ride'),
        backgroundColor: color.primary,
        foregroundColor: color.onPrimary,
      ),
      body: SafeArea(
        // <--- Wrap with SafeArea here
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
                        final loc = picked['latLng'];
                        final desc = picked['description'];
                        setState(() {
                          _fromLocation = loc;
                          _fromController.text = desc;
                        });
                        await _fetchRouteInfo();
                      },
                      onClear: () => setState(() {
                        _fromController.clear();
                        _fromLocation = null;
                      }),
                    ),
                    const SizedBox(height: 16),
                    LocationSelector(
                      label: 'Destination',
                      icon: Icons.location_on,
                      controller: _toController,
                      onLocationPicked: (picked) async {
                        final loc = picked['latLng'];
                        final desc = picked['description'];
                        setState(() {
                          _toLocation = loc;
                          _toController.text = desc;
                        });
                        await _fetchRouteInfo();
                      },
                      onClear: () => setState(() {
                        _toController.clear();
                        _toLocation = null;
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

              /// Route Preview
              if (_fromLocation != null &&
                  _toLocation != null &&
                  _distance != null)
                RoutePreviewSection(
                  from: _fromLocation!,
                  to: _toLocation!,
                  onRouteInfoLoaded: _handleRouteInfoLoaded,
                ),
              const SizedBox(height: 20),

              if (_distance != null && _duration != null && _fare != null)
                RouteInfoCard(
                  distanceInMeters: _distance! * 1000,
                  duration: _duration!,
                  fare: _fare!,
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
