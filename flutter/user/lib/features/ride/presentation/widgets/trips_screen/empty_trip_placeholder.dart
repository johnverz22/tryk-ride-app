import 'package:flutter/material.dart';

class EmptyTripPlaceholder extends StatelessWidget {
  final String category;
  final VoidCallback? onBookPressed;

  const EmptyTripPlaceholder({
    super.key,
    required this.category,
    this.onBookPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            'No $category Trips',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'You have no ${category.toLowerCase()} trips at the moment.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
