import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/widgets.dart';
import '../../../providers/driver_provider.dart';
import '../../../../data/models/ride_request_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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
    _selectedRide = ride;

    _autoAcceptTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) async {
      if (!mounted) return;
      setState(() => _remainingSeconds--);

      if (_remainingSeconds <= 0) {
        _cancelAutoAcceptTimer();
        if (!mounted) return;

        final updatedRide = await ref
            .read(driverProvider.notifier)
            .acceptRide(ride);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedRide != null
                  ? 'Ride auto-accepted.'
                  : 'Ride no longer available.',
            ),
            backgroundColor: updatedRide != null ? Colors.green : Colors.red,
          ),
        );

        setState(() => _selectedRide = null);
        if (updatedRide != null) {
          await _showDriverConfirmationDialog(
            context: context,
            riderName: updatedRide.riderName ?? 'Rider',
            profilePicture: updatedRide.riderProfilePicture,
          );
        }
      }
    });
  }

  void _cancelAutoAcceptTimer() {
    _autoAcceptTimer?.cancel();
    _autoAcceptTimer = null;
  }

  Future<void> _showDriverConfirmationDialog({
    required BuildContext context,
    required String riderName,
    required String? profilePicture,
  }) async {
    final result = await showModalBottomSheet(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return PopScope(
          canPop: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_transportation,
                  size: 48,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ride Accepted Successfully!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  '$riderName is waiting for you to pick up!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
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
                      child: (profilePicture?.isEmpty ?? true)
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
                        children: const [
                          Text(
                            '4.8',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 16),
                              SizedBox(width: 4),
                              Text('Rating'),
                            ],
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
                    onPressed: () =>
                        Navigator.of(context).pop('navigate_to_tracking'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
        );
      },
    );

    if (result == 'navigate_to_tracking') {
      // TODO: Navigator.pushNamed(context, '/tracking');
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverState = ref.watch(driverProvider);
    final rides = driverState.asData?.value?.requestedRides ?? [];

    final nearestRide = rides.isNotEmpty
        ? rides.reduce(
            (a, b) =>
                (a.distanceInKm ?? double.infinity) <
                    (b.distanceInKm ?? double.infinity)
                ? a
                : b,
          )
        : null;

    // Start countdown only when nearestRide changes
    if (nearestRide != null &&
        (_selectedRide == null || _selectedRide!.id != nearestRide.id)) {
      _startAutoAcceptTimer(nearestRide);
    }

    return Scaffold(
      appBar: CustomUserAppBar(),
      body: rides.isEmpty
          ? const Center(child: Text("No incoming ride requests."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rides.length,
              itemBuilder: (context, index) {
                final ride = rides[index];
                return _buildRideCard(
                  context,
                  ride,
                  ride.id == _selectedRide?.id,
                );
              },
            ),
    );
  }

  Widget _buildRideCard(
    BuildContext context,
    RideRequest ride,
    bool isSelected,
  ) {
    final provider = ref.read(driverProvider.notifier);
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ride rejected.'),
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
                      final updatedRide = await provider.acceptRide(ride);
                      if (_selectedRide?.id == ride.id) {
                        _cancelAutoAcceptTimer();
                        setState(() => _selectedRide = null);
                      }

                      if (updatedRide != null) {
                        await _showDriverConfirmationDialog(
                          context: context,
                          riderName: updatedRide.riderName ?? 'Rider',
                          profilePicture: updatedRide.riderProfilePicture,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Unable to accept the ride.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
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
