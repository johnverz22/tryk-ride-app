import 'package:flutter/material.dart';

class PlaceChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const PlaceChip({
    super.key,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: Colors.pink),
      label: Text(label),
      labelStyle: const TextStyle(fontWeight: FontWeight.w500),
      backgroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.grey, width: 0.2),
      ),
    );
  }
}
