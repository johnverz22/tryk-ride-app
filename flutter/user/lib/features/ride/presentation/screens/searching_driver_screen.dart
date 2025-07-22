import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:user/features/ride/presentation/providers/ride_cancellation_provider.dart';
import 'package:user/features/ride/presentation/providers/ride_booking_provider.dart';
import 'package:user/features/ride/presentation/widgets/ride_booking_screen/widgets.dart';

class ConfirmedDriverInfo {
  final String driverName;
  final String? profilePicture;
  final String vehicle;

  ConfirmedDriverInfo({
    required this.driverName,
    this.profilePicture,
    required this.vehicle,
  });
}

class SearchingDriverBottomSheet extends ConsumerStatefulWidget {
  final int rideId;
  // This callback is triggered when the user confirms they want to track the ride.
  final ValueChanged<void> onRideConfirmedAndTrack;

  const SearchingDriverBottomSheet({
    super.key,
    required this.rideId,
    required this.onRideConfirmedAndTrack,
  });

  @override
  ConsumerState<SearchingDriverBottomSheet> createState() =>
      _SearchingDriverBottomSheetState();
}

class _SearchingDriverBottomSheetState
    extends ConsumerState<SearchingDriverBottomSheet> {
  // Internal State
  bool _isCancelling = false;
  String _statusText = 'Looking for a nearby driver...';
  StreamSubscription? _rideStatusSubscription;

  // This flag controls the UI switch from "searching" to "confirmed".
  bool _driverFound = false;
  // This will hold the driver info once found.
  ConfirmedDriverInfo? _confirmedDriverInfo;

  @override
  void initState() {
    super.initState();
    _listenToRideStatus();
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted || _isCancelling) return;
      setState(() {
        _statusText = 'Matching you with the best driver...';
      });
    });
  }

  @override
  void dispose() {
    _rideStatusSubscription?.cancel();
    super.dispose();
  }

  void _listenToRideStatus() {
    _rideStatusSubscription?.cancel();
    final rideSocketService = ref.read(rideSocketServiceProvider);

    _rideStatusSubscription = rideSocketService
        .init(widget.rideId, (eventData) {
          if (!mounted || _isCancelling || _driverFound) return;

          final Map<String, dynamic> decoded = eventData;
          final String? rideStatusName = decoded['status']?['name']
              ?.toString()
              .toLowerCase();
          final Map<String, dynamic>? driverInfo = decoded['driver_info'];

          if (rideStatusName == 'accepted' && driverInfo != null) {
            _rideStatusSubscription?.cancel();

            final String driverName = driverInfo['name'] ?? 'Unknown Driver';
            final String? profilePicture = driverInfo['profile_picture'];
            final String vehicleModel =
                driverInfo['vehicle_model'] ?? 'Unknown Model';
            final String licensePlate = driverInfo['license_plate'] ?? 'N/A';
            final String vehicle = '$vehicleModel - $licensePlate';

            // Set the state to switch the UI inside the modal
            setState(() {
              _driverFound = true;
              _confirmedDriverInfo = ConfirmedDriverInfo(
                driverName: driverName,
                profilePicture: profilePicture,
                vehicle: vehicle,
              );
            });
          } else if (rideStatusName == 'cancelled') {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This ride request was cancelled.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        })
        .listen(
          (_) {},
          onError: (error) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Connection error: $error'),
                backgroundColor: Colors.red,
              ),
            );
          },
        );
  }

  Future<void> _cancelRide() async {
    setState(() {
      _isCancelling = true;
      _statusText = 'Cancelling...';
    });

    final subscription = ref.listenManual<AsyncValue<void>>(
      rideCancellationProvider,
      (previous, next) {
        if (!mounted) return;
        if (next is AsyncData) {
          Navigator.of(context).pop(); // Close the sheet on success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ride request has been cancelled.'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (next is AsyncError) {
          setState(() {
            _isCancelling = false;
            _statusText = 'Failed to cancel. Please try again.';
          });
        }
      },
    );

    await ref.read(rideCancellationProvider.notifier).cancel(widget.rideId);
    subscription.close();
  }

  @override
  Widget build(BuildContext context) {
    // This makes the modal non-dismissible by trapping back gestures.
    return PopScope(
      canPop: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: _driverFound
              ? _buildConfirmedStateUI(context, _confirmedDriverInfo!)
              : _buildSearchingStateUI(context),
        ),
      ),
    );
  }

  /// The UI to show while searching for a driver.
  Widget _buildSearchingStateUI(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('searching'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const PulsatingRadarAnimation(),
        const SizedBox(height: 24),
        Text(
          _statusText,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "We appreciate your patience!",
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isCancelling ? null : _cancelRide,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: _isCancelling ? Colors.grey : Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _isCancelling ? 'Cancelling...' : 'Cancel Ride Request',
              style: TextStyle(
                color: _isCancelling ? Colors.grey : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// The UI to show after a driver has been confirmed.
  Widget _buildConfirmedStateUI(
    BuildContext context,
    ConfirmedDriverInfo info,
  ) {
    return Column(
      key: const ValueKey('confirmed'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 60),
        const SizedBox(height: 16),
        Text(
          'Driver Confirmed!',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '${info.driverName} is on the way!',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.grey.shade200,
              backgroundImage:
                  (info.profilePicture != null &&
                      info.profilePicture!.isNotEmpty)
                  ? NetworkImage(info.profilePicture!)
                  : null,
              child:
                  (info.profilePicture == null || info.profilePicture!.isEmpty)
                  ? const Icon(Icons.person, size: 32, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.driverName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      SizedBox(width: 4),
                      Text('4.9'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(info.vehicle, style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.track_changes_rounded),
            label: const Text('Track Ride'),
            onPressed: () {
              // Dismiss the modal first
              Navigator.of(context).pop();
              // Then trigger the callback to navigate to the new screen
              widget.onRideConfirmedAndTrack(());
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
    );
  }
}
