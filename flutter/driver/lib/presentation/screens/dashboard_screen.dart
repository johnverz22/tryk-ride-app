import 'package:driver/presentation/widgets/earnings_widget/earnings_widgets.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Section 1: Today’s Summary
              const Text(
                "Today's Overview",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  TripStatTile(label: 'Trips', value: '7'),
                  TripStatTile(label: 'Earnings', value: '\$89.50'),
                  TripStatTile(label: 'Online', value: '4h 32m'),
                ],
              ),
              const SizedBox(height: 24),
      
              // 🔹 Section 2: Performance Metrics
              const Text(
                'Performance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  TripStatTile(label: 'Acceptance', value: '95%'),
                  TripStatTile(label: 'Rating', value: '4.91'),
                  TripStatTile(label: 'Cancel Rate', value: '2%'),
                ],
              ),
              const SizedBox(height: 24),
      
              // 🔹 Section 3: Weekly Earnings
              const Text(
                'Weekly Earnings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.deepPurple.shade50,
                ),
                alignment: Alignment.center,
                child: const Text(
                  '📊 Chart Coming Soon',
                  style: TextStyle(fontSize: 16, color: Colors.deepPurple),
                ),
              ),
      
              const SizedBox(height: 32),
      
              // 🔹 Section 4: Action Buttons (optional)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to earnings
                    },
                    icon: const Icon(Icons.monetization_on),
                    label: const Text('Earnings'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to trip history
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('History'),
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
