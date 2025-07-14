import 'package:flutter/material.dart';

class SuggestionCard extends StatelessWidget {
  final String label;
  final IconData icon;

  const SuggestionCard({super.key, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Selected: $label'))),
      child: Container(
        width: 130,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: Colors.blueAccent),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
