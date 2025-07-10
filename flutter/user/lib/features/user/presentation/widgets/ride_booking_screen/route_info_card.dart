import 'package:flutter/material.dart';
import 'package:user/config/currency.dart';
import 'info_tile.dart';

class RouteInfoCard extends StatelessWidget {
  final double distanceInMeters; // More accurate than km
  final String duration; // e.g., "25"
  final double fare; // e.g., "18.50"

  const RouteInfoCard({
    super.key,
    required this.distanceInMeters,
    required this.duration,
    required this.fare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final distanceInKm = distanceInMeters / 1000;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(top: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trip Summary',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                InfoTile(
                  icon: Icons.route,
                  label: '${distanceInKm.toStringAsFixed(1)} km',
                  color: Colors.blueAccent,
                ),
                InfoTile(
                  icon: Icons.schedule,
                  label:
                      '${double.tryParse(duration)?.toStringAsFixed(0) ?? duration} min',
                  color: Colors.deepOrange,
                ),
                InfoTile(
                  icon: Icons.attach_money,
                  label: currencyFormatter.format(fare),
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
