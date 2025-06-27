import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RoutePreviewMap extends StatefulWidget {
  final LatLng from;
  final LatLng to;
  final double totalDistance;

  const RoutePreviewMap({
    super.key,
    required this.from,
    required this.to,
    required this.totalDistance,
  });

  @override
  State<RoutePreviewMap> createState() => _RoutePreviewMapState();
}

class _RoutePreviewMapState extends State<RoutePreviewMap> {
  // Removed unused _mapController

  Set<Marker> get _markers => {
    Marker(
      markerId: const MarkerId('from'),
      position: widget.from,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    ),
    Marker(
      markerId: const MarkerId('to'),
      position: widget.to,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    ),
  };

  Set<Polyline> get _polylines => {
    Polyline(
      polylineId: const PolylineId('route'),
      points: [widget.from, widget.to],
      color: Theme.of(context).primaryColor,
      width: 5,
    ),
  };

  CameraPosition get _initialCameraPosition => CameraPosition(
    target: LatLng(
      (widget.from.latitude + widget.to.latitude) / 2,
      (widget.from.longitude + widget.to.longitude) / 2,
    ),
    zoom: widget.totalDistance <= 2
        ? 15
        : widget.totalDistance <= 5
        ? 13
        : 11,
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        child: GoogleMap(
          initialCameraPosition: _initialCameraPosition,
          markers: _markers,
          polylines: _polylines,
          onMapCreated: (controller) {
            // Map controller is available if needed in the future
          },
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          compassEnabled: false,
        ),
      ),
    );
  }
}
