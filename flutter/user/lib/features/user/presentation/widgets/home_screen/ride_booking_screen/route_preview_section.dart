import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../widgets.dart';

class RoutePreviewSection extends StatelessWidget {
  final LatLng from;
  final LatLng to;
  final double distance; // in km
  final double? distanceInMeters;
  final int? durationInSeconds;
  final void Function(double distance, int duration) onRouteInfoLoaded;

  final String? googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];

  static const double _baseFare = 5.0;
  static const double _perKmRate = 2.0;
  static const double _averageSpeedKmh = 40.0;

  RoutePreviewSection({
    required this.from,
    required this.to,
    required this.distance,
    required this.onRouteInfoLoaded,
    this.distanceInMeters,
    this.durationInSeconds,
    super.key,
  });

  double _getEstimatedCost(double km) => _baseFare + (_perKmRate * km);

  double _getEstimatedTimeInMinutes(double km) => km / _averageSpeedKmh * 60;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasRouteInfo = distanceInMeters != null && durationInSeconds != null;

    final double effectiveDistanceMeters =
        distanceInMeters ?? (distance * 1000);
    final String effectiveDurationMinutes = hasRouteInfo
        ? (durationInSeconds! / 60).toStringAsFixed(2)
        : _getEstimatedTimeInMinutes(distance).toStringAsFixed(2);

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
          onRouteInfoLoaded: (distance, duration) =>
              onRouteInfoLoaded(distance.toDouble(), duration),
        ),
        const SizedBox(height: 12),
        RouteInfoCard(
          cost: _getEstimatedCost(distance).toStringAsFixed(2),
          distanceInMeters: effectiveDistanceMeters,
          duration: effectiveDurationMinutes,
        ),
      ],
    );
  }
}
