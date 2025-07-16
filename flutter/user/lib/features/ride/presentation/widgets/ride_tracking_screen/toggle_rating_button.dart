import 'package:flutter/material.dart';

class ToggleRatingButton extends StatelessWidget {
  final bool isVisible;
  final VoidCallback onPressed;

  const ToggleRatingButton({
    required this.isVisible,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: Icon(
            isVisible ? Icons.visibility_off : Icons.visibility,
            color: Colors.white,
          ),
          label: Text(
            isVisible ? 'Hide Rating' : 'Show Rating',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
