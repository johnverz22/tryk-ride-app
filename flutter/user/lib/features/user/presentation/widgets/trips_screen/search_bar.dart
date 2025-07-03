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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Material(
        elevation: 1,
        borderRadius: BorderRadius.circular(16),
        child: TextField(
          onChanged: onChanged,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Search trips...',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            prefixIcon: const Icon(Icons.search, size: 24),
            suffixIcon: IconButton(
              icon: const Icon(Icons.filter_alt_outlined, size: 24),
              onPressed: onFilterPressed,
              tooltip: 'Filter trips',
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}
