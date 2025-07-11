import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../widgets.dart';

class RoutePreviewSection extends StatelessWidget {
  final LatLng from;
  final LatLng to;
  final double? distanceInKm;
  final double? durationInMinutes;
  final void Function(double distanceKm, double durationMinutes, double fare)
  onRouteInfoLoaded;

  final String? googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];

  static const double _baseFare = 5.0;
  static const double _perKmRate = 2.0;

  RoutePreviewSection({
    required this.from,
    required this.to,
    required this.onRouteInfoLoaded,
    this.distanceInKm,
    this.durationInMinutes,
    super.key,
  });

  double _getEstimatedFareFromKm(double km) {
    return _baseFare + (_perKmRate * km);
  }

  @override
  Widget build(BuildContext context) {
    final String effectiveDuration =
        durationInMinutes?.toStringAsFixed(2) ?? '--';

    final double? fare = distanceInKm != null
        ? _getEstimatedFareFromKm(distanceInKm!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.map,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Route Preview',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              RideMapPreview(
                key: ValueKey(
                  '${from.latitude},${from.longitude}-${to.latitude},${to.longitude}',
                ),
                fromLocation: from,
                toLocation: to,
                apiKey: googleMapsApiKey,
                onRouteInfoLoaded: (distanceKm, durationMin) {
                  final fare = _getEstimatedFareFromKm(distanceKm);
                  onRouteInfoLoaded(distanceKm, durationMin, fare);
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),
        if (fare != null)
          RouteInfoCard(
            fare: fare,
            distanceInMeters: distanceInKm! * 1000,
            duration: effectiveDuration,
          ),
      ],
    );
  }
}
