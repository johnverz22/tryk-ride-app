import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TripCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final VoidCallback? onViewDetails;
  final VoidCallback? onRebook;

  const TripCard({
    super.key,
    required this.trip,
    this.onViewDetails,
    this.onRebook,
  });

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Accepted':
        return Colors.orange;
      case 'Completed':
        return Colors.green;
      case 'Cancelled': // Match backend spelling
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
    );
  }

  /// Gets the correct datetime field based on trip status
  DateTime? _getRelevantDate(String status) {
    String? dateString;

    switch (status) {
      case 'Accepted':
        dateString = trip['accepted_at'];
        break;
      case 'Completed':
        dateString = trip['completed_at'];
        break;
      case 'Cancelled': // Match backend spelling
        dateString = trip['canceled_at'];
        break;
      default:
        dateString = trip['requested_at'];
    }

    return dateString != null ? DateTime.tryParse(dateString) : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final String status = trip['status'] ?? 'Unknown';
    final DateTime? tripDate = _getRelevantDate(status);
    final String pickup = trip['pickup_address'];
    final String dropoff = trip['dropoff_address'];
    final String payment = trip['payment_method'];
    final String driver = trip['driver'] ?? 'N/A';
    final double rating = (trip['rating'] ?? 0).toDouble();
    final double price = (trip['fare_amount'] ?? 0).toDouble();

    return Dismissible(
      key: ValueKey(trip['id']),
      background: Container(
        color: Colors.blue.shade100,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.replay, color: Colors.blue),
      ),
      direction: DismissDirection.endToStart,
      // Optional: enable this to trigger rebooking on swipe
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
                    tripDate != null
                        ? DateFormat('MMM dd, yyyy – hh:mm a').format(tripDate)
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
                    'Fare: ₱${price.toStringAsFixed(2)}',
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
                    'Driver: $driver ★ $rating',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (status == 'Completed')
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
