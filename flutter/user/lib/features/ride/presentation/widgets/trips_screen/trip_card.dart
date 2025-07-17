import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:user/config/currency.dart'; // Assuming currencyFormatter is defined here
import 'package:user/features/ride/domain/entities/trip_entity.dart';

class TripCard extends StatelessWidget {
  final TripEntity trip;
  final VoidCallback? onViewDetails;
  final VoidCallback? onRebook;

  const TripCard({
    super.key,
    required this.trip,
    this.onViewDetails,
    this.onRebook,
  });

  // Helper to determine status color based on TripEntity's statusName
  Color _getStatusColor(String? statusName) {
    switch (statusName?.toLowerCase()) {
      // Use toLowerCase for robust matching
      case 'accepted':
      case 'driver en route':
      case 'ride in progress':
      case 'ride started awaiting user confirmation': // Added from TripEntity's isOngoing
      case 'ride completed awaiting user confirmation': // Added from TripEntity's isOngoing
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  // Widget to display the status badge
  Widget _statusBadge(String statusName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(statusName),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        statusName,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
    );
  }

  // Removed _getRelevantDate method as we'll access DateTime properties directly

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Access properties directly from the TripEntity object
    final String status = trip.statusName;
    final String pickup = trip.pickupAddress;
    final String dropoff = trip.dropoffAddress;
    final String payment = trip.paymentMethod;
    final String driver =
        trip.driverName ?? 'N/A'; // Use driverName from entity
    final int? riderRating = trip.riderRating; // Use riderRating from entity
    final double price = trip.fareAmount; // Use fareAmount from entity

    // Determine the most relevant date to display
    final DateTime? displayDate =
        trip.completedAt ??
        trip.canceledAt ??
        trip.acceptedAt ??
        trip.requestedAt;

    return Dismissible(
      key: ValueKey(trip.id), // Use TripEntity's ID
      background: Container(
        color: Colors.blue.shade100,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.replay, color: Colors.blue),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        if (onRebook != null) onRebook!();
        return false; // prevent actual dismissal
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    displayDate != null
                        ? DateFormat(
                            'MMM dd, yyyy – hh:mm a',
                          ).format(displayDate)
                        : 'Date not available',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  _statusBadge(status),
                ],
              ),
              const SizedBox(height: 12),

              // Pickup & Dropoff
              _tripLocationRow(Icons.location_on, pickup),
              const SizedBox(height: 4),
              _tripLocationRow(Icons.flag, dropoff),
              const SizedBox(height: 12),

              // Price & Payment
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Fare: ${currencyFormatter.format(price)}', // Removed extra parenthesis
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text('Paid via $payment', style: theme.textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 8),

              // Driver & Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Driver: $driver ${riderRating != null ? '★ $riderRating' : ''}', // Display rating only if available
                    style: theme.textTheme.bodyMedium,
                  ),
                  // Only show Rebook button if status is 'Completed'
                  if (trip.isCompleted &&
                      onRebook != null) // Use TripEntity's helper
                    TextButton(
                      onPressed: onRebook,
                      child: const Text('Rebook'),
                    ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onViewDetails,
                  child: const Text('View Details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for location rows
  Widget _tripLocationRow(IconData icon, String label) {
    Color? iconColor;
    if (icon == Icons.location_on) {
      iconColor = Colors.green; // Pickup
    } else if (icon == Icons.flag) {
      iconColor = Colors.red; // Dropoff
    } else {
      iconColor = Colors.grey[600]; // Default
    }

    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
