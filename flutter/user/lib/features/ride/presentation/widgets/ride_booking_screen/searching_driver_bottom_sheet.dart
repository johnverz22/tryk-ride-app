import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user/features/ride/presentation/providers/ride_cancellation_provider.dart';
import 'package:user/features/ride/presentation/providers/ride_booking_provider.dart';
import 'package:user/features/ride/presentation/widgets/ride_booking_screen/widgets.dart';

class ConfirmedDriverInfo {
  final int rideId;
  final String driverName;
  final String? profilePicture;
  final String vehicle;

  ConfirmedDriverInfo({
    required this.rideId,
    required this.driverName,
    this.profilePicture,
    required this.vehicle,
  });
}

class SearchingDriverBottomSheet extends ConsumerStatefulWidget {
  final int rideId;
  final VoidCallback? cancelStatusCheck;
  final ValueChanged<ConfirmedDriverInfo>? onDriverConfirmed;

  const SearchingDriverBottomSheet({
    super.key,
    required this.rideId,
    this.cancelStatusCheck,
    this.onDriverConfirmed,
  });

  @override
  ConsumerState<SearchingDriverBottomSheet> createState() =>
      _SearchingDriverBottomSheetState();
}

class _SearchingDriverBottomSheetState
    extends ConsumerState<SearchingDriverBottomSheet> {
  bool _rideCancelled = false;
  String _statusText = 'Looking for a nearby driver...';

  // No longer `late final RideSocketService _socketService;`
  // It will be accessed directly via ref.read() in methods.
  StreamSubscription? _rideStatusSubscription; // Manage the stream subscription

  @override
  void initState() {
    super.initState();

    _listenToRideStatus();

    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted || _rideCancelled) return;
      setState(() {
        _statusText = 'Matching you with the best driver...';
      });
    });
  }

  void _listenToRideStatus() {
    _rideStatusSubscription?.cancel(); // Cancel any existing subscription

    // Get the RideSocketService instance from Riverpod
    final rideSocketService = ref.read(rideSocketServiceProvider);

    // Call init on the service, which now returns a Stream.
    // Then, listen to that stream.
    _rideStatusSubscription = rideSocketService
        .init(widget.rideId, (eventData) {
          // The `eventData` here is the `parsed` payload from `_socketService._parsePayload`
          // which is already a Map<String, dynamic>. No need for jsonDecode here.
          final Map<String, dynamic> decoded = eventData;

          if (!mounted || _rideCancelled) return;

          final String? rideStatusName = decoded['status']?['name']
              ?.toString()
              .toLowerCase();
          final Map<String, dynamic>? driverInfo = decoded['driver_info'];

          // Check for the 'accepted' status and presence of driver info
          if (rideStatusName == 'accepted' && driverInfo != null) {
            // Pop the current bottom sheet
            Navigator.of(context, rootNavigator: true).pop();

            if (!mounted) return;

            // Extract driver details from the eventData
            final String driverName = driverInfo['name'] ?? 'Unknown Driver';
            final String? profilePicture = driverInfo['profile_picture'];
            final String vehicleModel =
                driverInfo['vehicle_model'] ?? 'Unknown Model';
            final String licensePlate = driverInfo['license_plate'] ?? 'N/A';
            final String vehicle = '$vehicleModel - $licensePlate';

            widget.onDriverConfirmed?.call(
              ConfirmedDriverInfo(
                rideId: widget.rideId,
                driverName: driverName,
                profilePicture: profilePicture,
                vehicle: vehicle,
              ),
            );
          } else if (rideStatusName == 'cancelled') {
            // Handle cases where the ride is cancelled by the system or driver during search
            Navigator.of(context, rootNavigator: true).pop();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Ride request was cancelled by the system or driver.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        })
        .listen(
          (data) {
            // This `data` is the same `parsed` payload from the `onUpdate` callback above.
            // You can add additional logging or processing of stream data here if needed,
            // but the main logic for confirming the driver is handled in the `onUpdate` callback.
          },
          onError: (error) {
            if (!mounted) return;
            debugPrint(
              'WebSocket stream error in SearchingDriverBottomSheet: $error',
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Connection error: ${error.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          },
          onDone: () {
            debugPrint('WebSocket stream done in SearchingDriverBottomSheet.');
          },
        );
  }

  Future<void> _cancelRide() async {
    setState(() {
      _rideCancelled = true;
      _statusText = 'Cancelling ride...';
    });

    widget.cancelStatusCheck?.call();

    final sub = ref.listenManual(rideCancellationProvider, (previous, next) {
      if (!mounted) return;

      if (next is AsyncData) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ride request cancelled.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      } else if (next is AsyncError) {
        setState(() {
          _rideCancelled = false;
          _statusText = 'Failed to cancel ride.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel ride: ${next.error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }, fireImmediately: true);
    sub.close();
    await ref.read(rideCancellationProvider.notifier).cancel(widget.rideId);
  }

  @override
  void dispose() {
    _rideStatusSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Prevent user from dismissing the sheet with the back button
    return PopScope(
      canPop: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The new custom animation
            const PulsatingRadarAnimation(),
            const SizedBox(height: 24),

            // Animated status text for smooth transitions
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: Text(
                _statusText,
                key: ValueKey<String>(
                  _statusText,
                ), // Important for AnimatedSwitcher
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              "This will only take a moment. We appreciate your patience!",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // A cleaner, more modern cancel button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _rideCancelled ? null : _cancelRide,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(
                    color: _rideCancelled ? Colors.grey : Colors.red,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _rideCancelled ? 'Cancelling...' : 'Cancel Ride Request',
                  style: TextStyle(
                    color: _rideCancelled ? Colors.grey : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
