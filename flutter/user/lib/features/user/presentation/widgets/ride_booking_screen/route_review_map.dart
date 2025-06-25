import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

class RoutePreviewMap extends StatelessWidget {
  final LatLng from;
  final LatLng to;
  final MapController mapController;
  final double totalDistance;

  const RoutePreviewMap({
    super.key,
    required this.from,
    required this.to,
    required this.mapController,
    required this.totalDistance,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        child: FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: LatLng(
              (from.latitude + to.latitude) / 2,
              (from.longitude + to.longitude) / 2,
            ),
            initialZoom: (totalDistance <= 2)
                ? 15
                : (totalDistance <= 5)
                ? 13
                : 11,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: from,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.green,
                    size: 36,
                  ),
                ),
                Marker(
                  point: to,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 36,
                  ),
                ),
              ],
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: [from, to],
                  strokeWidth: 4.0,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
