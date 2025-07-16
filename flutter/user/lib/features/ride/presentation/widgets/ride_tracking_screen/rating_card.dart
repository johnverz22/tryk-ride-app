import 'package:flutter/material.dart';
import 'widgets.dart';

class RatingCard extends StatelessWidget {
  final Map<String, dynamic>? ride;
  final bool isVisible;
  final VoidCallback onToggle;

  const RatingCard({
    required this.ride,
    required this.isVisible,
    required this.onToggle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final rating = ride?['rider_rating'] ?? 0;
    final comment = ride?['rider_review']?.toString().trim();
    final hasComment = comment != null && comment.isNotEmpty;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DragIndicator(),
            const Center(
              child: Text(
                'Your Rating',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return Icon(
                    rating >= starIndex
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 34,
                    color: Colors.amber[600],
                  );
                }),
              ),
            ),
            if (hasComment) ...[
              const SizedBox(height: 24),
              const Text(
                'Comment',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '"$comment"',
                style: const TextStyle(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 20),
            ToggleRatingButton(isVisible: isVisible, onPressed: onToggle),
          ],
        ),
      ),
    );
  }
}
