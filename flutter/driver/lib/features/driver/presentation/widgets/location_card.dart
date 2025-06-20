import 'package:flutter/material.dart';

class LocationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const LocationCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Icon(icon, size: 28, color: Colors.pinkAccent),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: subtitle != null
            ? Text(subtitle!, style: const TextStyle(color: Colors.black54))
            : null,
      ),
    );
  }
}
