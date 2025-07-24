import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:user/config/currency.dart';
import 'package:user/features/ride/domain/entities/trip_entity.dart';

class TripCard extends StatelessWidget {
  final TripEntity trip;
  final VoidCallback? onViewDetails;

  const TripCard({super.key, required this.trip, this.onViewDetails});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

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
              _buildHeader(context, theme, displayDate, trip.statusName),
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
  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    DateTime displayDate,
    String status,
  ) {
    final date = DateFormat('EEE, MMM d, yyyy – h:mm a').format(displayDate);
    final String driver = trip.driverName ?? 'N/A';
    final int? riderRating = trip.riderRating;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: .1),
          child: Text(
            driver.substring(0, 1),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$driver ${riderRating != null ? '★ $riderRating' : ''}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
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
        _buildRouteIndicator(theme),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLocationText(trip.pickupAddress, 'Pickup', theme),
              const SizedBox(height: 24),
              _buildLocationText(trip.dropoffAddress, 'Dropoff', theme),
            ],
          ),
        ),
      ],
    );
  }

  // Footer: Contains Fare, Driver info, Payment Method, and Action buttons
  Widget _buildFooter(ThemeData theme) {
    final String paymentMethod = trip.paymentMethod;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildInfoChip(Icons.credit_card, 'Paid via $paymentMethod', theme),
            Text(
              currencyFormatter.format(trip.fareAmount),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildActionButtons(),
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

  Widget _buildRouteIndicator(ThemeData theme) {
    final themeColor = theme.primaryColor;
    return Column(
      children: [
        const SizedBox(height: 8),
        Icon(Icons.trip_origin, color: themeColor, size: 20),
        Container(height: 50, width: 1, color: Colors.grey[300]),
        Icon(Icons.location_on, color: themeColor, size: 20),
      ],
    );
  }

  // Helper for info chips (e.g., Driver, Payment)
  Widget _buildInfoChip(IconData icon, String text, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          text,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Action Buttons row
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
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
      default:
        return (
          color: Colors.orange.shade700,
          icon: Icons.access_time_filled_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _getStatusStyle();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.1),
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
