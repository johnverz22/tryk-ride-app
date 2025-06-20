import 'package:flutter/material.dart';
import '../../../widgets/widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isOnline = false;

  void toggleAvailability() {
    setState(() => isOnline = !isOnline);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomUserAppBar(), // Top bar: profile, settings
      body: Stack(
        children: [
          // 🔁 Placeholder for map (replace with GoogleMap widget)
          Container(
            height: double.infinity,
            color: Colors.grey[300],
            child: const Center(child: Text("📍 Real-time Map Placeholder")),
          ),

          // 🔁 Availability toggle (overlay on top of map)
          Positioned(
            top: 100,
            left: 16,
            right: 16,
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: ListTile(
                leading: Icon(
                  isOnline ? Icons.toggle_on : Icons.toggle_off,
                  size: 36,
                  color: isOnline ? Colors.green : Colors.grey,
                ),
                title: Text(
                  isOnline ? 'You’re Online' : 'You’re Offline',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                trailing: Switch(
                  value: isOnline,
                  onChanged: (_) => toggleAvailability(),
                  activeColor: Colors.green,
                ),
              ),
            ),
          ),

          // 🔁 Bottom summary (earnings, trips, time online)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  SummaryTile(label: 'Earnings', value: '\$128.50'),
                  SummaryTile(label: 'Trips', value: '8'),
                  SummaryTile(label: 'Online', value: '4h 15m'),
                ],
              ),
            ),
          ),

          // 🔁 Incoming ride overlay (optional/conditional)
          // Can be shown conditionally:
          // if (incomingRequest) Positioned(...)

        ],
      ),
    );
  }
}

class SummaryTile extends StatelessWidget {
  final String label;
  final String value;

  const SummaryTile({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }
}
