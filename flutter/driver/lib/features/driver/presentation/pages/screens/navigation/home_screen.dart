import 'dart:async';
import 'package:flutter/material.dart';
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
  Timer? _autoAcceptTimer;
  int _remainingSeconds = 30;

  @override
  void dispose() {
    _cancelAutoAcceptTimer();
    super.dispose();
  }

  void _startAutoAcceptTimer(RideRequest ride) {
    _cancelAutoAcceptTimer();
    _remainingSeconds = 30;

    _autoAcceptTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) async {
      if (!mounted) return;
      setState(() => _remainingSeconds--);

      if (_remainingSeconds <= 0) {
        _cancelAutoAcceptTimer();
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

        setState(() => _selectedRide = null);
      }
    });
  }

  void _cancelAutoAcceptTimer() {
    _autoAcceptTimer?.cancel();
    _autoAcceptTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverProvider>(context);
    final rides = driverProvider.requestedRides;

    final nearestRide = rides.isNotEmpty
        ? rides.reduce(
            (a, b) =>
                (a.distanceInKm ?? double.infinity) <
                    (b.distanceInKm ?? double.infinity)
                ? a
                : b,
          )
        : null;

    if (nearestRide != null &&
        (_selectedRide == null || _selectedRide!.id != nearestRide.id)) {
      _selectedRide = nearestRide;
      _startAutoAcceptTimer(nearestRide);
    }

    return Scaffold(
      appBar: CustomUserAppBar(
        isOnline: driverProvider.isOnline,
        onToggleOnline: (val) {
          if (!val) {
            _cancelAutoAcceptTimer();
            setState(() => _selectedRide = null);
          }
        },
      ),
      body: rides.isEmpty
          ? const Center(child: Text("No incoming ride requests."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rides.length,
              itemBuilder: (context, index) {
                final ride = rides[index];
                final isSelected = _selectedRide?.id == ride.id;
                return _buildRideCard(
                  context,
                  ride,
                  isSelected,
                  driverProvider,
                );
              },
            ),
    );
  }

  Widget _buildRideCard(
    BuildContext context,
    RideRequest ride,
    bool isSelected,
    DriverProvider provider,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 6,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${ride.pickupAddress} → ${ride.dropoffAddress}",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text("Fare: ₱${ride.fareAmount?.toStringAsFixed(2) ?? '--'}"),
            Text(
              "Distance: ${ride.distanceInKm?.toStringAsFixed(1) ?? '--'} km",
            ),
            Text(
              "Est. Duration: ${ride.durationInMinutes?.toStringAsFixed(0) ?? '--'} min",
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _buildAutoAcceptTimer(),
              ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.close, size: 20),
                    label: const Text("Decline"),
                    onPressed: () async {
                      await provider.rejectRide(ride);
                      if (_selectedRide?.id == ride.id) {
                        _cancelAutoAcceptTimer();
                        setState(() => _selectedRide = null);
                      }
                      await provider.fetchRequestedRides();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Ride rejected. Refreshed nearby rides.',
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 20),
                    label: const Text("Accept"),
                    onPressed: () async {
                      final success = await provider.acceptRequest(ride);
                      if (_selectedRide?.id == ride.id) {
                        _cancelAutoAcceptTimer();
                        setState(() => _selectedRide = null);
                      }
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Ride accepted successfully.'
                                : 'Unable to accept the ride.',
                          ),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoAcceptTimer() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: _remainingSeconds / 30,
                strokeWidth: 5,
                backgroundColor: Colors.grey[300],
                color: Colors.green,
              ),
            ),
            Text(
              '$_remainingSeconds',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Auto-accepting in $_remainingSeconds sec',
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
      ],
    );
  }
}
