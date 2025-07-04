import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class RideMapPreview extends StatefulWidget {
  final LatLng fromLocation;
  final LatLng toLocation;
  final String? apiKey;
  final Color routeColor;

  final void Function(double distanceKm, int durationMinutes)?
  onRouteInfoLoaded;

  const RideMapPreview({
    super.key,
    required this.fromLocation,
    required this.toLocation,
    required this.apiKey,
    this.routeColor = Colors.blue,
    this.onRouteInfoLoaded,
  });

  @override
  State<RideMapPreview> createState() => _RideMapPreviewState();
}

class _RideMapPreviewState extends State<RideMapPreview> {
  GoogleMapController? _mapController;
  List<LatLng> _routePoints = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    if (widget.apiKey == null || widget.apiKey!.isEmpty) {
      debugPrint("Google Maps API key is missing.");
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      return;
    }

    final origin = widget.fromLocation;
    final destination = widget.toLocation;

    final uri = Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
      'origin': '${origin.latitude},${origin.longitude}',
      'destination': '${destination.latitude},${destination.longitude}',
      'mode': 'driving',
      'key': widget.apiKey!,
    });

    try {
      final response = await http.get(uri);
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final route = data['routes'][0];
        final points = route['overview_polyline']['points'];
        final decoded = PolylinePoints().decodePolyline(points);

        // 🚀 Get distance and duration
        final leg = route['legs'][0];
        final distanceMeters = leg['distance']['value']; // meters
        final durationSeconds = leg['duration']['value']; // seconds

        setState(() {
          _routePoints = decoded
              .map((p) => LatLng(p.latitude, p.longitude))
              .toList();
          _isLoading = false;
        });

        // 🔔 Notify parent
        if (widget.onRouteInfoLoaded != null) {
          widget.onRouteInfoLoaded!(
            distanceMeters / 1000.0,
            (durationSeconds / 60).round(),
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch route: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng center = LatLng(
      (widget.fromLocation.latitude + widget.toLocation.latitude) / 2,
      (widget.fromLocation.longitude + widget.toLocation.longitude) / 2,
    );

    if (_isLoading) {
      return SizedBox(
        height: 220,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError) {
      return SizedBox(
        height: 220,
        child: const Center(child: Text('Unable to load route preview')),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: center,
            zoom: _calculateZoom(),
          ),
          markers: {
            Marker(
              markerId: const MarkerId('pickup'),
              position: widget.fromLocation,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            ),
            Marker(
              markerId: const MarkerId('dropoff'),
              position: widget.toLocation,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            ),
          },
          polylines: {
            if (_routePoints.isNotEmpty)
              Polyline(
                polylineId: const PolylineId('route'),
                color: widget.routeColor,
                width: 5,
                points: _routePoints,
              ),
          },
          onMapCreated: (controller) => _mapController = controller,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
          // liteModeEnabled: true,
        ),
      ),
    );
  }

  double _calculateZoom() {
    final distance = _calculateDistanceKm(
      widget.fromLocation.latitude,
      widget.fromLocation.longitude,
      widget.toLocation.latitude,
      widget.toLocation.longitude,
    );

    if (distance <= 2) return 15;
    if (distance <= 5) return 13;
    if (distance <= 10) return 12;
    if (distance <= 20) return 11;
    return 10;
  }

  double _calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371;
    final double dLat = _degToRad(lat2 - lat1);
    final double dLon = _degToRad(lon2 - lon1);

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double degree) => degree * pi / 180;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
