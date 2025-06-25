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
  Color getDistanceColor(double? distanceKm) {
    if (distanceKm == null) return Colors.grey;
    if (distanceKm < 5) return Colors.green; // short
    if (distanceKm < 10) return Colors.yellow; // moderate
    if (distanceKm < 15) return Colors.orange; // long
    return Colors.red; // very long
  }

  int? _fadingOutRideId;

  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverProvider>(context);

    return Scaffold(
      appBar: CustomUserAppBar(
        isOnline: driverProvider.isOnline,
        onToggleOnline: (val) async {
          await driverProvider.setOnlineStatus(val);
          setState(() {
            _selectedRide = null;
          });
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
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedRide = ride);
                        },
                        child: AnimatedOpacity(
                          opacity: _fadingOutRideId == ride.id ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            Icons.location_pin,
                            color: getDistanceColor(ride.distanceInKm),
                            size: 40,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),

          if (_selectedRide != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _selectedRide = null),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
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

                          // Ride Details
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
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "💰 Fare",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      "₱${_selectedRide!.fareAmount?.toStringAsFixed(2) ?? 'N/A'}",
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "🛣️ Distance",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      "${_selectedRide!.distanceInKm?.toStringAsFixed(2) ?? 'N/A'} km",
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "⏱️ Est. Time",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      "${_selectedRide!.durationInMinutes?.toStringAsFixed(0) ?? 'N/A'} min",
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Action Buttons
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
                                        const Duration(milliseconds: 300),
                                      );

                                      driverProvider.rejectSpecificRide(
                                        _selectedRide!,
                                      );
                                      setState(() {
                                        _selectedRide = null;
                                        _fadingOutRideId = null;
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

                                      if (!mounted) return;

                                      if (success) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Ride accepted successfully.',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            backgroundColor: Colors.green[600],
                                            duration: Duration(seconds: 3),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Unable to accept the ride. It may no longer be available.',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            backgroundColor: Colors.red[600],
                                            duration: Duration(seconds: 4),
                                          ),
                                        );
                                      }

                                      setState(() => _selectedRide = null);
                                    },
                                    icon: const Icon(Icons.check),
                                    label: const Text("Accept"),
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
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
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  SummaryTile(
                    icon: Icons.attach_money,
                    label: 'Earnings',
                    value: '₱128.50',
                  ),
                  SummaryTile(
                    icon: Icons.directions_car_filled,
                    label: 'Trips',
                    value: '8',
                  ),
                  SummaryTile(
                    icon: Icons.timer_outlined,
                    label: 'Online',
                    value: '4h 15m',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const SummaryTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 26, color: theme.colorScheme.primary),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }
}
