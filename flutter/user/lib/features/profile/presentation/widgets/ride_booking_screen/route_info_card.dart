import 'package:flutter/material.dart';
import 'package:user/config/currency.dart';
import 'info_tile.dart';

class RouteInfoCard extends StatelessWidget {
  final double distanceInMeters; // More accurate than km
  final double duration; // e.g., "25"
  final double fare; // e.g., "18.50"

  const RouteInfoCard({
    super.key,
    required this.distanceInMeters,
    required this.duration,
    required this.fare,
  });

  @override
  Widget build(BuildContext context) {
    final distanceInKm = distanceInMeters / 1000;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                'Trip Summary',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
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
                label: '${duration.toStringAsFixed(0)} min',
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
    );
  }
}
