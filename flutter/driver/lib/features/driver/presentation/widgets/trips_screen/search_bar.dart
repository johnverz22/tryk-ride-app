import 'package:flutter/material.dart';

class TripSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback? onFilterPressed;

  const TripSearchBar({
    super.key,
    required this.onChanged,
    this.onFilterPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search trips',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: onFilterPressed,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
