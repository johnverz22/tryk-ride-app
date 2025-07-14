import 'package:flutter/material.dart';

class SaveChangesButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isEnabled;
  final String label;
  final IconData icon;

  const SaveChangesButton({
    super.key,
    required this.onPressed,
    this.isEnabled = true,
    this.label = 'Save Changes',
    this.icon = Icons.save,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 16, 32, 48),
        child: FilledButton.icon(
          onPressed: isEnabled ? onPressed : null,
          icon: Icon(icon),
          label: Text(label),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: theme.colorScheme.primary,
            disabledBackgroundColor: theme.disabledColor,
          ),
        ),
      ),
    );
  }
}
