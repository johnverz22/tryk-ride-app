// vehicle_preferences_screen.dart
import 'package:flutter/material.dart';

class VehiclePreferencesScreen extends StatefulWidget {
  const VehiclePreferencesScreen({super.key});

  @override
  State<VehiclePreferencesScreen> createState() => _VehiclePreferencesScreenState();
}

class _VehiclePreferencesScreenState extends State<VehiclePreferencesScreen> {
  final Map<String, bool> vehicleTypes = {
    'Economy': false,
    'Comfort': false,
    'Premium': false,
    'Electric': false,
  };

  final Map<String, bool> additionalPrefs = {
    'Quiet Ride': false,
    'Temperature Control': false,
    'Extra Luggage Space': false,
  };

  void _toggleSelection(Map<String, bool> map, String key) {
    setState(() {
      map[key] = !(map[key] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle Preferences')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('Select your preferred vehicle types', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...vehicleTypes.keys.map((type) => CheckboxListTile(
                  title: Text(type),
                  subtitle: Text(
                    type == 'Economy'
                        ? 'Affordable rides'
                        : type == 'Comfort'
                            ? 'Spacious sedans'
                            : type == 'Premium'
                                ? 'Luxury vehicles'
                                : 'Eco-friendly',
                  ),
                  value: vehicleTypes[type],
                  onChanged: (_) => _toggleSelection(vehicleTypes, type),
                )),
            const Divider(height: 32),
            const Text('Additional Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...additionalPrefs.keys.map((pref) => CheckboxListTile(
                  title: Text(pref),
                  value: additionalPrefs[pref],
                  onChanged: (_) => _toggleSelection(additionalPrefs, pref),
                )),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Save Preferences'),
            ),
          ],
        ),
      ),
    );
  }
}
