import 'package:flutter/material.dart';

class DriverSearchRadiusSlider extends StatelessWidget {
  final double radiusKm;
  final void Function(double) onChanged;

  const DriverSearchRadiusSlider({
    required this.radiusKm,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
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
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.primary.withAlpha(50),
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
            max: 50,
            divisions: 9,
            label: radiusKm.toStringAsFixed(0),
            activeColor: color.primary,
            inactiveColor: Colors.grey[300],
            onChanged: onChanged,
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('5 km', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text('50 km', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}
