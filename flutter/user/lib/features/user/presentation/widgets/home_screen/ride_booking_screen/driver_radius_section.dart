import 'package:flutter/material.dart';

class DriverRadiusSection extends StatelessWidget {
  final double radiusKm;
  final ValueChanged<double> onRadiusChanged;

  const DriverRadiusSection({
    super.key,
    required this.radiusKm,
    required this.onRadiusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.radar, color: color.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Driver Search Radius',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${radiusKm.toStringAsFixed(0)} km',
                  style: TextStyle(
                    color: color.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Slider(
            value: radiusKm,
            min: 5,
            max: 100,
            divisions: 19,
            label: radiusKm.toStringAsFixed(0),
            activeColor: color.primary,
            inactiveColor: Colors.grey[300],
            onChanged: onRadiusChanged,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('5 km', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(
                '100 km',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
