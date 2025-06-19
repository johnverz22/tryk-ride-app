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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Upcoming':
        return Colors.orange;
      case 'Completed':
        return Colors.green;
      case 'Canceled':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dismissible(
      key: ValueKey(trip['id']),
      background: Container(
        color: Colors.blue.shade100,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.replay, color: Colors.blue),
      ),
      direction: DismissDirection.endToStart,
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
                    DateFormat('MMM dd, yyyy – hh:mm a').format(trip['datetime']),
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(trip['status']),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      trip['status'],
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Pickup & Dropoff
              _tripLocationRow(Icons.location_on, trip['pickup']),
              const SizedBox(height: 4),
              _tripLocationRow(Icons.flag, trip['dropoff']),
              const SizedBox(height: 12),

              // Price & Payment
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Cost: \$${trip['price'].toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium),
                  Text('Paid via ${trip['payment']}', style: theme.textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 8),

              // Driver & Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Driver: ${trip['driver']} ★ ${trip['rating']}',
                      style: theme.textTheme.bodyMedium),
                  if (trip['status'] == 'Completed')
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
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
      ],
    );
  }
}
