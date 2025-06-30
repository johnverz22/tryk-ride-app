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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.airport_shuttle_outlined, size: 72, color: Colors.grey),
          const SizedBox(height: 12),
          Text('No $category trips found.', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onBookPressed,
            child: const Text('Book a new ride'),
          ),
        ],
      ),
    );
  }
}
