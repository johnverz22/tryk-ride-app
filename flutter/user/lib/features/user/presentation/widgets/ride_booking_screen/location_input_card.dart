import 'package:flutter/material.dart';
import '../../pages/screens/navigation/home/location_picker_screen.dart';

class LocationInputCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final Future<void> Function(Map<String, dynamic>) onLocationPicked;
  final VoidCallback onClear;

  const LocationInputCard({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    required this.onLocationPicked,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: TextField(
          controller: controller,
          readOnly: true,
          onTap: () async {
            final picked = await Navigator.push<Map<String, dynamic>>(
              context,
              MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
            );
            if (picked != null) {
              await onLocationPicked(picked);
            }
          },
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear), onPressed: onClear)
                : null,
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}
