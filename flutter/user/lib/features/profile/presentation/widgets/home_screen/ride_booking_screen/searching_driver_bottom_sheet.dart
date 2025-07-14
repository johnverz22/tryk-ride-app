import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../../../core/services/auth_service.dart';

class SearchingDriverBottomSheet extends StatefulWidget {
  final String? baseUrl;
  final int? rideId;
  final VoidCallback? onCancelled;
  final VoidCallback? cancelStatusCheck;

  const SearchingDriverBottomSheet({
    super.key,
    this.baseUrl,
    this.rideId,
    this.onCancelled,
    this.cancelStatusCheck,
  });

  @override
  State<SearchingDriverBottomSheet> createState() =>
      _SearchingDriverBottomSheetState();
}

class _SearchingDriverBottomSheetState
    extends State<SearchingDriverBottomSheet> {
  final DraggableScrollableController _controller =
      DraggableScrollableController();
  bool _rideCancelled = false;
  String _statusText = 'Looking for a nearby driver...';

  @override
  void initState() {
    super.initState();
    // Update text after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted || _rideCancelled) return;
      setState(() {
        _statusText = 'Matching you with the best driver...';
      });
    });
  }

  Future<void> _cancelRide() async {
    setState(() {
      _rideCancelled = true;
      _statusText = 'Cancelling ride...';
    });

    // Cancel the ride
    final token = await AuthService().getToken();
    if (token != null && widget.rideId != null && widget.baseUrl != null) {
      final uri = Uri.parse('${widget.baseUrl}/rides/cancel');
      await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'ride_id': widget.rideId}),
      );
    }

    widget.cancelStatusCheck?.call();

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ride request cancelled.')));
      widget.onCancelled?.call();
    }
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
