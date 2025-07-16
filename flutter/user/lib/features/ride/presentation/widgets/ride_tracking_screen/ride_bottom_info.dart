import 'package:user/config/currency.dart';
import 'package:user/features/ride/presentation/widgets/ride_tracking_screen/widgets.dart';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'info_tile.dart'; // if you extracted this too
import 'rating_card.dart';
import 'rating_form.dart';
import 'toggle_rating_button.dart';
import 'drag_indicator.dart';

class RideBottomInfo extends StatelessWidget {
  final Map<String, dynamic>? ride;
  final Map<String, dynamic>? driver;
  final bool hasSubmittedRating;
  final bool showRatingForm;
  final bool showSubmittedRating;
  final double selectedRating;
  final TextEditingController reviewController;
  final void Function(double) onRatingSelected;
  final VoidCallback onSubmitRating;
  final VoidCallback onToggleRatingCard;
  final VoidCallback onCancelRatingForm;
  final VoidCallback onOpenRatingForm;
  final ValueChanged<bool> onToggleSubmittedRating;

  const RideBottomInfo({
    super.key,
    required this.ride,
    required this.driver,
    required this.hasSubmittedRating,
    required this.showRatingForm,
    required this.showSubmittedRating,
    required this.selectedRating,
    required this.reviewController,
    required this.onRatingSelected,
    required this.onSubmitRating,
    required this.onCancelRatingForm,
    required this.onOpenRatingForm,
    required this.onToggleSubmittedRating,
    required this.onToggleRatingCard,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final rideStatus =
          ride?['status']?['name']?.toString().toLowerCase() ?? '';
      final alreadyRated = ride?['rider_rating'] != null;

      final showRateButton =
          rideStatus == 'completed' && !alreadyRated && !hasSubmittedRating;

      final driverName = (driver?['name'] as String?) ?? 'Unknown Driver';
      final driverVehicle = (driver?['plate'] as String?) ?? 'No vehicle info';
      final distanceKm = ride?['distance_km'];
      final durationMin = ride?['duration_minutes'];
      final fareAmount = ride?['fare_amount'];
      final photoUrl = driver?['photo_url'] as String?;
      final isPhotoValid = photoUrl != null && photoUrl.trim().isNotEmpty;

      return Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const DragIndicator(),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: isPhotoValid
                            ? NetworkImage(photoUrl)
                            : null,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: !isPhotoValid
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driverName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              driverVehicle,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Status: ${ride?['status']?['name'] ?? 'Unknown'}",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () async {
                              final phoneNumber = driver?['phone'];
                              if (phoneNumber is String &&
                                  phoneNumber.isNotEmpty) {
                                final uri = Uri.parse('tel:$phoneNumber');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
                              }
                            },
                            icon: Icon(
                              Icons.phone,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              final phoneNumber = driver?['phone'];
                              if (phoneNumber is String &&
                                  phoneNumber.isNotEmpty) {
                                final uri = Uri.parse('sms:$phoneNumber');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
                              }
                            },
                            icon: Icon(
                              Icons.message,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (distanceKm != null)
                        InfoTile(
                          icon: Icons.route,
                          value: '$distanceKm km',
                          label: 'Distance',
                        ),
                      if (durationMin != null)
                        InfoTile(
                          icon: Icons.timer,
                          value: '${durationMin.ceil()} min',
                          label: 'ETA',
                        ),
                      if (fareAmount != null)
                        InfoTile(
                          icon: Icons.payment,
                          value: currencyFormatter.format(fareAmount),
                          label: 'Fare',
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!showRatingForm && showRateButton)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onOpenRatingForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.star, color: Colors.white),
                        label: const Text(
                          'Rate Driver',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  if (rideStatus == 'completed' && alreadyRated)
                    ToggleRatingButton(
                      isVisible: showSubmittedRating,
                      onPressed: onToggleRatingCard,
                    ),
                ],
              ),
            ),
          ),
          if (showRatingForm)
            RatingForm(
              selectedRating: selectedRating,
              onRatingSelected: onRatingSelected,
              reviewController: reviewController,
              onSubmit: onSubmitRating,
              onCancel: onCancelRatingForm,
            ),
          if (showSubmittedRating)
            RatingCard(
              ride: ride,
              isVisible: showSubmittedRating,
              onToggle: onToggleRatingCard,
            ),
        ],
      );
    } catch (e) {
      debugPrint('Error building RideBottomInfo: $e');
      return const SizedBox.shrink();
    }
  }
}
