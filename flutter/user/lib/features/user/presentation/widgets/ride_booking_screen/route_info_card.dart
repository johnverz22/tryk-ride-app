import 'package:flutter/material.dart';
import 'info_tile.dart';

class RouteInfoCard extends StatelessWidget {
  final double distance;
  final String duration;
  final String cost;

  const RouteInfoCard({
    super.key,
    required this.distance,
    required this.duration,
    required this.cost,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(top: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trip Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InfoTile(
                  icon: Icons.route,
                  label: '${distance.toStringAsFixed(2)} km',
                  color: Colors.blueAccent,
                ),
                InfoTile(
                  icon: Icons.schedule,
                  label: duration,
                  color: Colors.deepOrange,
                ),
                InfoTile(
                  icon: Icons.attach_money,
                  label: cost,
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
