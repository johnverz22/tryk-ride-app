import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:user/config/currency.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Determine the most relevant date to display
    final DateTime displayDate =
        trip.completedAt ??
        trip.canceledAt ??
        trip.acceptedAt ??
        trip.requestedAt;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      child: InkWell(
        onTap: onViewDetails,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme, displayDate, trip.statusName),
              const SizedBox(height: 16),
              _buildRouteInfo(theme),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              _buildFooter(theme),
            ],
          ),
        ),
      ),
    );
  }

  // Header: Contains Date and Status Badge
  Widget _buildHeader(ThemeData theme, DateTime displayDate, String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          DateFormat('MMM dd, yyyy – hh:mm a').format(displayDate),
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        _StatusBadge(status: status),
      ],
    );
  }

  // Body: Contains Pickup and Dropoff locations with a visual route line
  Widget _buildRouteInfo(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRouteIndicator(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLocationText(trip.pickupAddress, 'Pickup', theme),
              const SizedBox(height: 24), // Space between pickup and dropoff
              _buildLocationText(trip.dropoffAddress, 'Dropoff', theme),
            ],
          ),
        ),
      ],
    );
  }

  // Footer: Contains Fare, Driver info, Payment Method, and Action buttons
  Widget _buildFooter(ThemeData theme) {
    final String driver = trip.driverName ?? 'N/A';
    final int? riderRating = trip.riderRating;
    final String paymentMethod = trip.paymentMethod;

    return Column(
      children: [
        Row(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align items to the top
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // --- START: MODIFIED SECTION ---
            // Group driver and payment info in a column
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoChip(
                  Icons.person_outline,
                  '$driver ${riderRating != null ? '★ $riderRating' : ''}',
                  theme,
                ),
                const SizedBox(height: 8),
                _buildInfoChip(
                  Icons.credit_card, // Icon for payment method
                  'Paid via $paymentMethod',
                  theme,
                ),
              ],
            ),
            // --- END: MODIFIED SECTION ---
            Text(
              currencyFormatter.format(trip.fareAmount),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildActionButtons(theme),
      ],
    );
  }

  // Helper for location text with a label
  Widget _buildLocationText(String address, String label, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 2),
        Text(
          address,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // Visual indicator for the route (from -> to)
  Widget _buildRouteIndicator() {
    return Column(
      children: [
        const SizedBox(height: 4),
        const Icon(Icons.trip_origin, color: Colors.green, size: 20),
        Container(height: 30, width: 1, color: Colors.grey[300]),
        const Icon(Icons.location_on, color: Colors.red, size: 20),
      ],
    );
  }

  // Helper for info chips (e.g., Driver, Payment)
  Widget _buildInfoChip(IconData icon, String text, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(text, style: theme.textTheme.bodyMedium),
      ],
    );
  }

  // Action Buttons row
  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Only show Rebook button if trip is completed and callback exists
        if (trip.isCompleted && onRebook != null)
          TextButton(onPressed: onRebook, child: const Text('Rebook')),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: onViewDetails,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('View Details'),
        ),
      ],
    );
  }
}

// A dedicated widget for the status badge for better code organization
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  // Helper to determine status color and icon
  ({Color color, IconData icon}) _getStatusStyle() {
    switch (status.toLowerCase()) {
      case 'completed':
        return (color: Colors.green.shade700, icon: Icons.check_circle);
      case 'cancelled':
        return (color: Colors.red.shade700, icon: Icons.cancel);
      default: // Ongoing statuses
        return (color: Colors.orange.shade700, icon: Icons.hourglass_top);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _getStatusStyle();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: style.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(style.icon, color: style.color, size: 14),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              color: style.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
