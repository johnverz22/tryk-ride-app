import 'package:flutter/material.dart';

class LocationTapField extends StatelessWidget {
  final String label;
  final bool isPlaceholder;
  final VoidCallback onTap;

  const LocationTapField({
    super.key,
    required this.label,
    required this.isPlaceholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: isPlaceholder ? FontWeight.normal : FontWeight.w600,
            color: isPlaceholder
                ? Colors.grey[600]
                : theme.textTheme.bodyLarge?.color,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
