// ride_booking_screen.dart

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../screens/navigation/home/location_picker_screen.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../../core/config/api_config.dart';

class RideBookingScreen extends StatefulWidget {
  const RideBookingScreen({super.key});

  @override
  State<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends State<RideBookingScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  LatLng? _fromLocation;
  LatLng? _toLocation;
  int? _rideId;
  Timer? _statusCheckTimer;

  static const int requestedStatusId = 1;

  final Distance _distance = const Distance();
  final double _averageSpeedKmh = 40;
  final double _baseFare = 2.5;
  final double _perKmRate = 1.2;

  final MapController _mapController = MapController();

  String _selectedPaymentMethod = 'Cash';
  bool _isLoading = false;
  bool _rideCancelled = false;
  bool _isBottomSheetOpen = false;

  String _getEstimatedTime(double km) =>
      '${(km / _averageSpeedKmh * 60).toStringAsFixed(0)} min';

  String _getEstimatedCost(double km) =>
      '\$${(_baseFare + _perKmRate * km).toStringAsFixed(2)}';

  Future<String> _reverseGeocode(LatLng location) async {
    final url =
        'https://nominatim.openstreetmap.org/reverse?lat=${location.latitude}&lon=${location.longitude}&format=json';
    final response = await http.get(
      Uri.parse(url),
      headers: {'User-Agent': 'Flutter App'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['display_name'] ?? 'Unknown Location';
    } else {
      return 'Lat: ${location.latitude}, Lng: ${location.longitude}';
    }
  }

  Future<void> _checkRideStatusPeriodically() async {
    final token = await AuthService().getToken();
    if (token == null || _rideId == null) return;

    _statusCheckTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/rides/$_rideId');

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
          timer.cancel();
          _statusCheckTimer = null;

          if (_isBottomSheetOpen && mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            _isBottomSheetOpen = false;

            await Future.delayed(
              Duration(milliseconds: 200),
            ); // smooth transition
          }

          if (mounted) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              backgroundColor: Colors.white,
              builder: (_) {
                final driver = ride['driver'];
                final profilePicture = driver['profile_picture'];
                final vehicle = driver['vehicle'] ?? 'Toyota Vios';
                final driverName = driver['name'];

                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emoji_transportation,
                        size: 48,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Driver Confirmed!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$driverName is on the way to pick you up.',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundImage:
                                profilePicture != null &&
                                    profilePicture.isNotEmpty
                                ? NetworkImage(profilePicture)
                                : null,
                            backgroundColor: Colors.grey[300],
                            child:
                                profilePicture == null || profilePicture.isEmpty
                                ? Icon(
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
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
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
                          icon: Icon(Icons.verified),
                          label: Text('Great, thanks!'),
                          onPressed: () {
                            if (!mounted) return;
                            Navigator.of(context).pop();
                          },

                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            textStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        }
      }
    });
  }

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
                  if (mounted && !_rideCancelled) {
                    setSheetState(() {
                      statusText = 'Matching you with the best driver...';
                    });
                  }
                });

                return DraggableScrollableSheet(
                  controller: controller,
                  initialChildSize: 0.3,
                  minChildSize: 0.3,
                  maxChildSize: 0.5,
                  builder: (BuildContext context, ScrollController scrollController) {
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
                                setSheetState(
                                  () => statusText = 'Cancelling ride...',
                                );

                                setState(() => _rideCancelled = true);

                                final token = await AuthService().getToken();

                                if (token != null &&
                                    _fromLocation != null &&
                                    _toLocation != null) {
                                  final uri = Uri.parse(
                                    '${ApiConfig.baseUrl}/rides/cancel',
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

                                setState(() => _rideId = null);

                                if (context.mounted) {
                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pop();

                                  // Show cancellation feedback after sheet is closed
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Ride request cancelled.'),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.cancel, color: Colors.red),
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

  Future<void> _requestRide() async {
    if (_fromLocation == null || _toLocation == null) return;

    final double distance = _distance.as(
      LengthUnit.Kilometer,
      _fromLocation!,
      _toLocation!,
    );
    final double fare = _baseFare + _perKmRate * distance;
    final double durationMinutes = distance / _averageSpeedKmh * 60;
    final now = DateTime.now().toIso8601String();

    final uri = Uri.parse('${ApiConfig.baseUrl}/rides/request');
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    final double? totalDistance = (_fromLocation != null && _toLocation != null)
        ? _distance.as(LengthUnit.Kilometer, _fromLocation!, _toLocation!)
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
            _buildLocationInputCard(
              label: 'Pickup Location',
              icon: Icons.my_location,
              controller: _fromController,
              onLocationPicked: (loc) async {
                final address = await _reverseGeocode(loc);
                setState(() {
                  _fromLocation = loc;
                  _fromController.text = address;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildLocationInputCard(
              label: 'Destination',
              icon: Icons.location_on,
              controller: _toController,
              onLocationPicked: (loc) async {
                final address = await _reverseGeocode(loc);
                setState(() {
                  _toLocation = loc;
                  _toController.text = address;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPaymentMethod,
              decoration: const InputDecoration(
                labelText: 'Payment Method',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              items: ['Cash', 'Card', 'Wallet']
                  .map(
                    (method) =>
                        DropdownMenuItem(value: method, child: Text(method)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedPaymentMethod = value);
                }
              },
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
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 220,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(
                        (_fromLocation!.latitude + _toLocation!.latitude) / 2,
                        (_fromLocation!.longitude + _toLocation!.longitude) / 2,
                      ),
                      initialZoom: (totalDistance <= 2)
                          ? 15
                          : (totalDistance <= 5)
                          ? 13
                          : 11,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _fromLocation!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.green,
                              size: 36,
                            ),
                          ),
                          Marker(
                            point: _toLocation!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [_fromLocation!, _toLocation!],
                            strokeWidth: 4.0,
                            color: theme.primaryColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildRouteInfoCard(
                cost: _getEstimatedCost(totalDistance),
                distance: totalDistance,
                duration: _getEstimatedTime(totalDistance),
              ),
            ],
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

  Widget _buildLocationInputCard({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required Function(LatLng) onLocationPicked,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: TextField(
          controller: controller,
          readOnly: true,
          onTap: () async {
            final LatLng? picked = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
            );
            if (picked != null) {
              onLocationPicked(picked);
            }
          },
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        controller.clear();
                        if (label == 'Pickup Location') _fromLocation = null;
                        if (label == 'Destination') _toLocation = null;
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildRouteInfoCard({
    required double distance,
    required String duration,
    required String cost,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(top: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trip Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoTile(
                  icon: Icons.route,
                  label: '${distance.toStringAsFixed(2)} km',
                  color: Colors.blueAccent,
                ),
                _buildInfoTile(
                  icon: Icons.schedule,
                  label: duration,
                  color: Colors.deepOrange,
                ),
                _buildInfoTile(
                  icon: Icons.attach_money,
                  label: cost,
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = null;
    super.dispose();
  }
}
