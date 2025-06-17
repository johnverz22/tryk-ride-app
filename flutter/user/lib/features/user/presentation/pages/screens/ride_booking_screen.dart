import 'package:flutter/material.dart';

class RideBookingScreen extends StatelessWidget {
  const RideBookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF4F46E5);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Ride'),
        backgroundColor: primaryColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildRideOption('Economy', '\$12.50', '4 seats • 5 min away', '12 min', isSelected: true),
          _buildRideOption('Comfort', '\$18.75', '4 seats • 8 min away', '12 min'),
          _buildRideOption('Premium', '\$25.00', '4 seats • 3 min away', '12 min'),
          const SizedBox(height: 24),
          const Text('•••• 4582', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Confirm ride logic here
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Request Economy', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildRideOption(String title, String price, String details, String eta, {bool isSelected = false}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Colors.indigo.shade50 : Colors.white,
      child: ListTile(
        leading: Icon(Icons.directions_car, color: isSelected ? Colors.indigo : Colors.grey),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$details\n$eta'),
        trailing: Text(price, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        isThreeLine: true,
      ),
    );
  }
}
