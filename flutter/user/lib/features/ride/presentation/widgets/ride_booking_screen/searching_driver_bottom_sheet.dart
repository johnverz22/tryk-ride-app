import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user/features/core/network/dio_provider.dart';
// REMOVE THIS IMPORT: import 'package:user/features/profile/presentation/pages/screens/navigation/home/ride_tracking_screen.dart';
import 'package:user/features/ride/data/services/ride_socket_service.dart';
import 'package:user/features/ride/presentation/providers/ride_cancellation_provider.dart';

// NEW: Define a data class for confirmed driver info
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
  // NEW: Callback to notify parent about confirmed driver
  final ValueChanged<ConfirmedDriverInfo>? onDriverConfirmed;

  const SearchingDriverBottomSheet({
    super.key,
    required this.rideId,
    this.cancelStatusCheck,
    this.onDriverConfirmed, // Add to constructor
  });

  @override
  ConsumerState<SearchingDriverBottomSheet> createState() =>
      _SearchingDriverBottomSheetState();
}

class _SearchingDriverBottomSheetState
    extends ConsumerState<SearchingDriverBottomSheet> {
  final DraggableScrollableController _controller =
      DraggableScrollableController();
  bool _rideCancelled = false;
  String _statusText = 'Looking for a nearby driver...';

  late final RideSocketService _socketService;

  @override
  void initState() {
    super.initState();

    final dio = ref.read(dioProvider);
    _socketService = RideSocketService(dio);

    _listenToRideStatus();

    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted || _rideCancelled) return;
      setState(() {
        _statusText = 'Matching you with the best driver...';
      });
    });
  }

  // REMOVE this method completely: _showDriverConfirmedModal
  // It will now be shown by RideBookingScreen

  void _listenToRideStatus() {
    _socketService.init(widget.rideId, (eventData) async {
      final decoded = eventData is String ? jsonDecode(eventData) : eventData;

      if (!mounted || _rideCancelled) return;

      final rideStatusId = decoded['ride_status_id'];
      final assignedDriverId = decoded['assigned_driver_id'];

      if (rideStatusId == 2 && assignedDriverId != null) {
        // First, close *this* bottom sheet (SearchingDriverBottomSheet)
        // using its own context.
        Navigator.of(context, rootNavigator: true).pop();

        if (!mounted) return; // Re-check mounted after pop

        // 👉 Replace the below mock values with real API call or provider state
        final driverName = 'John Doe'; // Replace with real name
        final profilePicture = ''; // Replace with driver image URL
        final vehicle =
            'Toyota Prius - ABC 1234'; // Replace with real vehicle info

        // Notify the parent (RideBookingScreen) that a driver is confirmed
        // and pass the relevant data.
        widget.onDriverConfirmed?.call(
          ConfirmedDriverInfo(
            rideId: widget.rideId,
            driverName: driverName,
            profilePicture: profilePicture,
            vehicle: vehicle,
          ),
        );
        return; // Important: Exit after handling confirmed driver
      }
    });
  }

  Future<void> _cancelRide() async {
    setState(() {
      _rideCancelled = true;
      _statusText = 'Cancelling ride...';
    });

    widget.cancelStatusCheck?.call();

    try {
      await ref.read(rideCancellationProvider.notifier).cancel(widget.rideId);

      if (!mounted) return;

      // Close the searching bottom sheet when cancelled
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
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to cancel ride.')));
    }
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _controller,
      initialChildSize: 0.3,
      minChildSize: 0.3,
      maxChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
          child: ListView(
            controller: scrollController,
            children: [
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  _statusText,
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
                  onPressed: _cancelRide,
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
  }
}
