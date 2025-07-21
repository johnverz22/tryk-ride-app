import 'package:flutter/material.dart';
import 'package:user/config/currency.dart';

/// A modern, visually intuitive widget for displaying and handling trip location inputs.
class LocationInputDisplay extends StatelessWidget {
  final String fromAddress;
  final String toAddress;
  final VoidCallback onFromTap;
  final VoidCallback onToTap;

  // Define placeholder text as constants for easy comparison and maintenance.
  static const String pickupPlaceholder = 'Pickup Location';
  static const String dropoffPlaceholder = 'Where to?';

  const LocationInputDisplay({
    super.key,
    required this.fromAddress,
    required this.toAddress,
    required this.onFromTap,
    required this.onToTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      // Use a subtle shadow for a modern feel.
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
        child: Row(
          children: [
            // The visual route indicator (from -> to).
            _buildRouteIndicator(context),
            const SizedBox(width: 12),
            // The tappable text fields.
            Expanded(
              child: Column(
                children: [
                  _LocationTapField(
                    label: fromAddress,
                    isPlaceholder: fromAddress == pickupPlaceholder,
                    onTap: onFromTap,
                  ),
                  const Divider(height: 16),
                  _LocationTapField(
                    label: toAddress,
                    isPlaceholder: toAddress == dropoffPlaceholder,
                    onTap: onToTap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the vertical line indicator with start and end points.
  Widget _buildRouteIndicator(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(Icons.trip_origin, color: theme.colorScheme.primary, size: 22),
        Container(height: 30, width: 2, color: Colors.grey[200]),
        Icon(Icons.location_on, color: theme.colorScheme.primary, size: 22),
      ],
    );
  }
}

/// A private helper widget for a single tappable location field.
class _LocationTapField extends StatelessWidget {
  final String label;
  final bool isPlaceholder;
  final VoidCallback onTap;

  const _LocationTapField({
    required this.label,
    required this.isPlaceholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: isPlaceholder ? FontWeight.normal : FontWeight.w600,
            color: isPlaceholder
                ? Colors.grey[600]
                : theme.textTheme.bodyLarge?.color,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// A modern card displaying the key metrics (fare, distance, time) for a calculated route.
class RouteInfoCard extends StatelessWidget {
  final double distanceInMeters;
  final double duration;
  final double fare;

  const RouteInfoCard({
    super.key,
    required this.distanceInMeters,
    required this.duration,
    required this.fare,
  });

  @override
  Widget build(BuildContext context) {
    final distanceInKm = distanceInMeters / 1000;
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Primary Info: The Fare
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Standard Fare',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormatter.format(fare),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Vertical divider for clean separation
            Container(
              height: 40,
              width: 1,
              color: Colors.grey[300],
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),

            // Secondary Info: Distance and Time
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _InfoDetail(
                    icon: Icons.route_outlined,
                    value: '${distanceInKm.toStringAsFixed(1)} km',

                    label: 'Distance',
                  ),
                  const SizedBox(height: 12),
                  _InfoDetail(
                    icon: Icons.schedule,
                    value: '~${duration.toStringAsFixed(0)} min',
                    label: 'Estimated Time',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A private helper for displaying a small piece of info with an icon, value, and label.
class _InfoDetail extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _InfoDetail({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
