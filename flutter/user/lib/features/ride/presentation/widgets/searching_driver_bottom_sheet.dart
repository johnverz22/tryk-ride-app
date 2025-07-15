import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user/features/core/network/dio_provider.dart';
import 'package:user/features/ride/data/services/ride_socket_service.dart';
import 'package:user/features/ride/presentation/providers/ride_cancellation_provider.dart';

class SearchingDriverBottomSheet extends ConsumerStatefulWidget {
  final int rideId;
  final VoidCallback? onCancelled;
  final VoidCallback? cancelStatusCheck;

  const SearchingDriverBottomSheet({
    super.key,
    required this.rideId,
    this.onCancelled,
    this.cancelStatusCheck,
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

  void _listenToRideStatus() {
    _socketService.init(widget.rideId, (eventData) {
      final decoded = eventData is String ? jsonDecode(eventData) : eventData;
      final status = decoded['status'];

      if (!mounted || _rideCancelled) return;

      switch (status) {
        case 'accepted':
          Navigator.of(context, rootNavigator: true).pop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Driver found!')));
          break;
        case 'cancelled':
          setState(() {
            _rideCancelled = true;
            _statusText = 'Ride was cancelled.';
          });
          break;
        default:
          setState(() {
            _statusText = 'Status updated: $status';
          });
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

      Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ride request cancelled.')));

      widget.onCancelled?.call();
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
