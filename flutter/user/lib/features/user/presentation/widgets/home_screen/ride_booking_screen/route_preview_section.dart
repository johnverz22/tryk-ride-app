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
    final theme = Theme.of(context);

    final String effectiveDuration =
        durationInMinutes?.toStringAsFixed(2) ?? '--';

    final double? fare = distanceInKm != null
        ? _getEstimatedFareFromKm(distanceInKm!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Text(
          'Route Preview',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
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
        const SizedBox(height: 12),
        if (fare != null)
          RouteInfoCard(
            cost: fare.toStringAsFixed(2),
            distanceInMeters: distanceInKm! * 1000,
            duration: effectiveDuration,
          ),
      ],
    );
  }
}
