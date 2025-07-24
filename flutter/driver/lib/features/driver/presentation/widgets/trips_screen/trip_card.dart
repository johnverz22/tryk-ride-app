import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DriverTripCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final VoidCallback? onViewDetails;

  const DriverTripCard({super.key, required this.trip, this.onViewDetails});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // --- Data Mapping ---
    final DateTime displayDate =
        DateTime.tryParse(trip['accepted_at'] ?? '') ?? DateTime.now();
    final String riderName = trip['user']?['name'] ?? 'Unknown Rider';
    final String status = trip['status']?['name'] ?? 'Unknown';

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
              _buildHeader(theme, riderName, displayDate, status),
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

  // Header: Combines Driver's info with User's status badge style
  Widget _buildHeader(
    ThemeData theme,
    String riderName,
    DateTime displayDate,
    String status,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
          child: Text(
            riderName.isNotEmpty ? riderName[0] : 'R',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                riderName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEE, MMM dd, yyyy – hh:mm a').format(displayDate),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        _StatusBadge(status: status),
      ],
    );
  }

  // Body: Inspired by User's card with visual route line
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
              _buildLocationText(
                trip['pickup_address'] ?? 'Unknown Pickup',
                'Pickup',
                theme,
              ),
              const SizedBox(height: 24),
              _buildLocationText(
                trip['dropoff_address'] ?? 'Unknown Destination',
                'Dropoff',
                theme,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Footer: Contains Fare and Payment Method
  Widget _buildFooter(ThemeData theme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildInfoChip(
              Icons.credit_card,
              'Paid via ${trip['payment_method'] ?? 'N/A'}',
              theme,
            ),
            Text(
              '₱${(trip['fare_amount'] ?? 0).toStringAsFixed(2)}',
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

  // Visual indicator for the route (from -> to)
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

  // Helper for info chips
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

// Dedicated widget for the status badge, inspired by user's card
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

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
