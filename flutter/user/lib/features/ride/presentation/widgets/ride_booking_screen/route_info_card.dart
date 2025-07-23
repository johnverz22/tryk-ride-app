import 'package:flutter/material.dart';
import 'package:user/config/currency.dart';
import 'package:user/features/ride/presentation/widgets/ride_booking_screen/widgets.dart';

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
                  InfoDetail(
                    icon: Icons.route_outlined,
                    value: '${distanceInKm.toStringAsFixed(1)} km',

                    label: 'Distance',
                  ),
                  const SizedBox(height: 12),
                  InfoDetail(
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
