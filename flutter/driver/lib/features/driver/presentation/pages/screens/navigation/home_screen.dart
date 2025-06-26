import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../widgets/widgets.dart';
import '../../../providers/driver_provider.dart';
import '../../../../data/models/ride_request_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  RideRequest? _selectedRide;
  int? _fadingOutRideId;
  Timer? _autoAcceptTimer;
  int _remainingSeconds = 30;
  bool _showRideList = false;

  Color getDistanceColor(double? distanceKm) {
    if (distanceKm == null) return Colors.grey;
    if (distanceKm < 5) return Colors.green;
    if (distanceKm < 10) return Colors.yellow;
    if (distanceKm < 15) return Colors.orange;
    return Colors.red;
  }

  void _startAutoAcceptTimer(RideRequest ride) {
    _autoAcceptTimer?.cancel();
    _remainingSeconds = 30;

    setState(() {
      _showRideList = false;
    });

    _autoAcceptTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (!mounted) return;

      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        _autoAcceptTimer?.cancel();
        final success = await Provider.of<DriverProvider>(
          context,
          listen: false,
        ).acceptRequest(ride);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Ride auto-accepted.' : 'Ride no longer available.',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        setState(() {
          _selectedRide = null;
          _showRideList = !success;
        });
      }
    });
  }

  void _cancelAutoAcceptTimer() {
    _autoAcceptTimer?.cancel();
  }

  @override
  void dispose() {
    _autoAcceptTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverProvider>(context);

    final nearestRide = driverProvider.requestedRides.isNotEmpty
        ? driverProvider.requestedRides.reduce(
            (a, b) =>
                (a.distanceInKm ?? double.infinity) <
                    (b.distanceInKm ?? double.infinity)
                ? a
                : b,
          )
        : null;

    if (nearestRide != null &&
        (_selectedRide == null || _selectedRide!.id != nearestRide.id)) {
      if (_autoAcceptTimer?.isActive != true) {
        _selectedRide = nearestRide;
        _startAutoAcceptTimer(nearestRide);
      }
    }

    return Scaffold(
      appBar: CustomUserAppBar(
        isOnline: driverProvider.isOnline,
        onToggleOnline: (val) async {
          if (!val) {
            _cancelAutoAcceptTimer();
            setState(() {
              _selectedRide = null;
              _showRideList = false;
            });
          }
        },
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(16.6156, 120.3198),
              initialZoom: 13,
              keepAlive: true,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              if (driverProvider.isOnline)
                MarkerLayer(
                  markers: driverProvider.requestedRides.map((ride) {
                    return Marker(
                      point: LatLng(ride.pickupLatitude, ride.pickupLongitude),
                      width: 40,
                      height: 40,
                      child: AnimatedOpacity(
                        opacity: _fadingOutRideId == ride.id ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.location_pin,
                          color: getDistanceColor(ride.distanceInKm),
                          size: 40,
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),

          // Show Ride Requests Button
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: ElevatedButton.icon(
              icon: Icon(
                _showRideList ? Icons.arrow_drop_down : Icons.arrow_drop_up,
              ),
              label: Text(
                _showRideList ? 'Hide Ride Requests' : 'Show Ride Requests',
              ),
              onPressed: _selectedRide == null
                  ? () {
                      setState(() {
                        _showRideList = !_showRideList;
                      });
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Ride Request List
          if (_showRideList)
            Positioned(
              bottom: 90,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: driverProvider.requestedRides.map((ride) {
                    final isSelected = _selectedRide?.id == ride.id;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      leading: Icon(
                        Icons.location_pin,
                        color: getDistanceColor(ride.distanceInKm),
                      ),
                      title: Text(
                        '${ride.pickupAddress} → ${ride.dropoffAddress}',
                      ),
                      subtitle: Text(
                        '₱${ride.fareAmount?.toStringAsFixed(2) ?? '--'} • ${ride.distanceInKm?.toStringAsFixed(1) ?? '--'} km',
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedRide = ride;
                          _showRideList = false;
                        });
                        _startAutoAcceptTimer(ride);
                      },
                    );
                  }).toList(),
                ),
              ),
            ),

          // Auto-Accept Dialog
          if (_selectedRide != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  _cancelAutoAcceptTimer();
                  setState(() => _selectedRide = null);
                },
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text(
                              "🚖 Ride Request",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: Column(
                              children: [
                                const SizedBox(height: 10),
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 70,
                                      height: 70,
                                      child: CircularProgressIndicator(
                                        value: _remainingSeconds / 30,
                                        strokeWidth: 6,
                                        backgroundColor: Colors.grey[300],
                                        color: Colors.green,
                                      ),
                                    ),
                                    Text(
                                      '$_remainingSeconds',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Auto-accepting in $_remainingSeconds sec',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "📍 Pickup",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(_selectedRide!.pickupAddress),
                                const SizedBox(height: 8),
                                Text(
                                  "🏁 Dropoff",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(_selectedRide!.dropoffAddress),
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 16),
                                _buildRideInfoRow(
                                  "💰 Fare",
                                  "₱${_selectedRide!.fareAmount?.toStringAsFixed(2) ?? 'N/A'}",
                                ),
                                _buildRideInfoRow(
                                  "🛣️ Distance",
                                  "${_selectedRide!.distanceInKm?.toStringAsFixed(2) ?? 'N/A'} km",
                                ),
                                _buildRideInfoRow(
                                  "⏱️ Est. Time",
                                  "${_selectedRide!.durationInMinutes?.toStringAsFixed(0) ?? 'N/A'} min",
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      setState(
                                        () => _fadingOutRideId =
                                            _selectedRide!.id,
                                      );
                                      await Future.delayed(
                                        Duration(milliseconds: 300),
                                      );
                                      await driverProvider.rejectSpecificRide(
                                        _selectedRide!,
                                      );
                                      _cancelAutoAcceptTimer();
                                      setState(() {
                                        _selectedRide = null;
                                        _fadingOutRideId = null;
                                        _showRideList = true;
                                      });
                                    },
                                    icon: const Icon(Icons.close),
                                    label: const Text("Decline"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final success = await driverProvider
                                          .acceptRequest(_selectedRide!);
                                      _cancelAutoAcceptTimer();
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            success
                                                ? 'Ride accepted successfully.'
                                                : 'Unable to accept the ride.',
                                          ),
                                          backgroundColor: success
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      );
                                      setState(() => _selectedRide = null);
                                    },
                                    icon: const Icon(Icons.check),
                                    label: const Text("Accept"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[600],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRideInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}
