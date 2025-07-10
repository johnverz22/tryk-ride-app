import 'package:flutter/material.dart';
import '../../widgets.dart';

class LocationSelector extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final void Function(Map<String, dynamic>) onLocationPicked;
  final VoidCallback onClear;

  const LocationSelector({
    required this.label,
    required this.icon,
    required this.controller,
    required this.onLocationPicked,
    required this.onClear,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocationInputCard(
          label: label,
          icon: icon,
          controller: controller,
          onLocationPicked: (location) async => onLocationPicked(location),
          onClear: onClear,
        ),
      ],
    );
  }
}
