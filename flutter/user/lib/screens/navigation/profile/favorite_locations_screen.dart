// favorite_locations_screen.dart
import 'package:flutter/material.dart';

class FavoriteLocationsScreen extends StatelessWidget {
  const FavoriteLocationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locations = [
      {'label': 'Home', 'address': '123 Main St, San Francisco, CA'},
      {'label': 'Work', 'address': '555 Market St, San Francisco, CA'},
      {'label': 'Favorite Restaurant', 'address': '399 The Embarcadero, San Francisco, CA'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Favorite Locations')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: locations.length,
        itemBuilder: (_, index) {
          final loc = locations[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.place, color: Colors.indigo),
              title: Text(loc['label']!),
              subtitle: Text(loc['address']!),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.grey),
                onPressed: () {},
              ),
            ),
          );
        },
      ),
    );
  }
}
