import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng? _selectedPoint;
  final MapController _mapController = MapController();

  final List<Map<String, dynamic>> _favoriteLocations = [
    {
      'name': 'Home',
      'latLng': LatLng(16.6155, 120.3170),
      'icon': Icons.home,
    },
    {
      'name': 'Work',
      'latLng': LatLng(16.6140, 120.3200),
      'icon': Icons.work,
    },
    {
      'name': 'Coffee Shop',
      'latLng': LatLng(16.6185, 120.3145),
      'icon': Icons.local_cafe,
    },
    {
      'name': 'Gym',
      'latLng': LatLng(16.6123, 120.3180),
      'icon': Icons.fitness_center,
    },
    {
      'name': 'Library',
      'latLng': LatLng(16.6160, 120.3195),
      'icon': Icons.local_library,
    },
  ];

  void _selectFavoriteLocation(LatLng latLng) {
    setState(() {
      _selectedPoint = latLng;
    });
    _mapController.move(latLng, 15);
  }

  void _showMoreLocationsBottomSheet(List<Map<String, dynamic>> locations) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: locations.map((place) {
            return ListTile(
              leading: Icon(place['icon'], color: Theme.of(context).primaryColor),
              title: Text(place['name']),
              onTap: () {
                Navigator.pop(context);
                _selectFavoriteLocation(place['latLng']);
              },
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final topFavorites = _favoriteLocations.take(2).toList();
    final moreFavorites = _favoriteLocations.skip(2).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(16.6167, 120.3167),
              initialZoom: 13,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedPoint = point;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.user',
              ),
              if (_selectedPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPoint!,
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.location_on,
                        color: theme.primaryColor,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Favorite chips (hybrid: top 2 + expandable "More")
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  ...topFavorites.map((place) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          avatar: Icon(place['icon'], size: 20),
                          label: Text(place['name']),
                          onPressed: () => _selectFavoriteLocation(place['latLng']),
                          backgroundColor: Colors.white,
                          shape: StadiumBorder(
                            side: BorderSide(color: theme.primaryColor),
                          ),
                          labelStyle: TextStyle(color: theme.primaryColor),
                        ),
                      )),
                  if (moreFavorites.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: const Icon(Icons.expand_more),
                        label: const Text('More'),
                        onPressed: () => _showMoreLocationsBottomSheet(moreFavorites),
                        backgroundColor: Colors.white,
                        shape: StadiumBorder(
                          side: BorderSide(color: theme.primaryColor),
                        ),
                        labelStyle: TextStyle(color: theme.primaryColor),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Coordinate info
          if (_selectedPoint != null)
            Positioned(
              top: 72,
              left: 16,
              right: 16,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Lat: ${_selectedPoint!.latitude.toStringAsFixed(5)}, '
                    'Lng: ${_selectedPoint!.longitude.toStringAsFixed(5)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),

      // Confirm button
      floatingActionButton: _selectedPoint != null
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pop(context, _selectedPoint);
              },
              backgroundColor: theme.primaryColor,
              icon: const Icon(Icons.check),
              label: const Text('Confirm'),
            )
          : null,
    );
  }
}
