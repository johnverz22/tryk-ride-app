import 'package:flutter/material.dart';

class RecentTripTile extends StatelessWidget {
  final String title;
  final String subtitle;

  const RecentTripTile({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tileColor: Colors.white,
        leading: const Icon(Icons.history, color: Colors.grey),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.black54)),
      ),
    );
  }
}
