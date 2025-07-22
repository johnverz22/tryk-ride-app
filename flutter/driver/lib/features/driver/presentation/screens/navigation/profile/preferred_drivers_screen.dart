// preferred_drivers_screen.dart
import 'package:flutter/material.dart';

class PreferredDriversScreen extends StatelessWidget {
  const PreferredDriversScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> drivers = [
      {'name': 'Daniel Wilson', 'rating': 4.92, 'favorite': true},
      {'name': 'Sarah Johnson', 'rating': 4.87, 'favorite': true},
      {'name': 'Michael Brown', 'rating': 4.95, 'favorite': false},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Preferred Drivers')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: drivers.length,
        itemBuilder: (_, index) {
          final driver = drivers[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.indigo,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(driver['name'] as String),
              subtitle: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(driver['rating'].toString()),
                ],
              ),
              trailing: driver['favorite'] == true
                  ? const Chip(label: Text('Favorite'))
                  : TextButton(
                      onPressed: () {},
                      child: const Text('Add Favorite'),
                    ),
            ),
          );
        },
      ),
    );
  }
}
