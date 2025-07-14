import 'package:flutter/material.dart';

class PaymentOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const PaymentOptionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withOpacity(0.08)
                : null,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? theme.colorScheme.primary : Colors.grey[300]!,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? theme.colorScheme.primary : Colors.grey[600],
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: selected
                      ? theme.colorScheme.primary
                      : Colors.grey[700],
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
