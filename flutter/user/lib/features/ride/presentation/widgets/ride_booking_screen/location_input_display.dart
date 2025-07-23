import 'package:flutter/material.dart';
import 'package:user/features/ride/presentation/widgets/ride_booking_screen/widgets.dart';

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
                  LocationTapField(
                    label: fromAddress,
                    isPlaceholder: fromAddress == pickupPlaceholder,
                    onTap: onFromTap,
                  ),
                  const Divider(height: 16),
                  LocationTapField(
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
