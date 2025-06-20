import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/widgets.dart'; // Make sure this includes CustomUserAppBar
import '../../../providers/driver_provider.dart'; // Adjust the import path accordingly

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverProvider>(context);

    return Scaffold(
      appBar: CustomUserAppBar(
        isOnline: driverProvider.isOnline,
        onToggleOnline: (val) => driverProvider.setOnlineStatus(val),
      ),
      body: Stack(
        children: [
          // 🌍 Replace with GoogleMap in production
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[200],
            child: const Center(
              child: Text(
                "📍 Real-time Map Placeholder",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ),

          // 📊 Summary Bottom Card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  SummaryTile(icon: Icons.attach_money, label: 'Earnings', value: '\$128.50'),
                  SummaryTile(icon: Icons.directions_car_filled, label: 'Trips', value: '8'),
                  SummaryTile(icon: Icons.timer_outlined, label: 'Online', value: '4h 15m'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const SummaryTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 26, color: theme.colorScheme.primary),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }
}
