import 'package:flutter/material.dart';
import '../../../widgets/widgets.dart';
import 'package:provider/provider.dart';
import '../../../providers/driver_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final driverProvider = Provider.of<DriverProvider>(context);

    return Scaffold(
      appBar: CustomUserAppBar(
        isOnline: driverProvider.isOnline,
        onToggleOnline: (val) => driverProvider.setOnlineStatus(val),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Today’s Overview
            Text('Today’s Overview', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    TripStatTile(label: 'Trips', value: '7'),
                    TripStatTile(label: 'Earnings', value: '\$89.50'),
                    TripStatTile(label: 'Online', value: '4h 32m'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 🔹 Performance Section
            Text('Performance', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    TripStatTile(label: 'Acceptance', value: '95%'),
                    TripStatTile(label: 'Rating', value: '4.91'),
                    TripStatTile(label: 'Cancel Rate', value: '2%'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 🔹 Weekly Earnings Chart
            Text('Weekly Earnings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.deepPurple.shade50,
              elevation: 1,
              child: SizedBox(
                height: 160,
                child: Center(
                  child: Text(
                    '📊 Chart Coming Soon',
                    style: theme.textTheme.bodyLarge?.copyWith(color: Colors.deepPurple),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 🔹 Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to earnings screen
                    },
                    icon: const Icon(Icons.monetization_on),
                    label: const Text('Earnings'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to history screen
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('History'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
