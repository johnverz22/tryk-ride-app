import 'package:flutter/material.dart';
import '../ride_booking_screen.dart';
import '../../../widgets/custom_top_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF4F46E5); // Brand color

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        toolbarHeight: 75,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            CustomTopBar(
              userName: 'John Doe',
              profileImageUrl: 'https://example.com/profile.jpg',
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Where are you going?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.my_location),
              title: const Text('Current Location'),
              subtitle: const Text('123 Main Street, San Francisco'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Enter destination'),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Saved Places', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('See All', style: TextStyle(color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildPlaceChip('Home', Icons.home),
              _buildPlaceChip('Work', Icons.work),
              _buildPlaceChip('Favorite Cafe', Icons.local_cafe),
              _buildPlaceChip('Mall', Icons.store),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Recent Trips', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Golden Gate Park'),
            subtitle: const Text('501 Stanyan St, San Francisco'),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Union Square'),
            subtitle: const Text('333 Post St, San Francisco'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RideBookingScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Search Rides', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 20),
      label: Text(label),
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
