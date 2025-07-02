import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng? _selectedPoint;
  GoogleMapController? _mapController;
  String? googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];

  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  String? _selectedDescription;

  final List<Map<String, dynamic>> _favoriteLocations = [
    {'name': 'Home', 'latLng': LatLng(16.6155, 120.3170), 'icon': Icons.home},
    {'name': 'Work', 'latLng': LatLng(16.6140, 120.3200), 'icon': Icons.work},
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

  void _selectFavoriteLocation(LatLng latLng, {String? description}) async {
    // Only use reverse geocoding if description is generic (like "Home", "Work", etc.)
    final isGeneric = [
      'Home',
      'Work',
      'Gym',
      'Library',
      'Coffee Shop',
    ].contains(description);
    final placeName = isGeneric
        ? await _getPlaceNameFromLatLng(latLng)
        : description;

    setState(() {
      _selectedPoint = latLng;
      _selectedDescription = placeName;
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
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
              leading: Icon(
                place['icon'],
                color: Theme.of(context).primaryColor,
              ),
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

  Future<void> _goToMyLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permissions are permanently denied.'),
        ),
      );
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final currentLatLng = LatLng(position.latitude, position.longitude);

    final placeName = await _getPlaceNameFromLatLng(currentLatLng);
    setState(() {
      _selectedPoint = currentLatLng;
      _selectedDescription = placeName;
    });
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(currentLatLng, 15),
    );
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) return;
    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$googleMapsApiKey&components=country:ph';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() => _searchResults = data['predictions']);
    } else {
      setState(() => _searchResults = []);
    }
  }

  Future<void> _selectPlace(String placeId, String description) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$googleMapsApiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final location = data['result']['geometry']['location'];
      final latLng = LatLng(location['lat'], location['lng']);

      setState(() {
        _selectedPoint = latLng;
        _selectedDescription = description;
        _searchResults = [];
        _searchController.clear();
        _isSearching = false;
      });

      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
    }
  }

  Future<String> _getPlaceNameFromLatLng(LatLng latLng) async {
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=$googleMapsApiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        final results = data['results'] as List;

        // 1. Try best formatted address (skip Unnamed Road or plus codes)
        for (final result in results) {
          final address = result['formatted_address'].toString().toLowerCase();
          if (!address.contains('unnamed road') && !address.contains('+')) {
            return result['formatted_address'];
          }
        }

        // 2. Try nearest landmark
        for (final result in results) {
          final components = result['address_components'] as List<dynamic>;
          for (final comp in components) {
            final types = comp['types'] as List<dynamic>;
            if (types.contains('point_of_interest') ||
                types.contains('establishment')) {
              return comp['long_name'];
            }
          }
        }

        // 3. Try sublocality, locality, or administrative area
        for (final result in results) {
          final components = result['address_components'] as List<dynamic>;
          for (final comp in components) {
            final types = comp['types'] as List<dynamic>;
            if (types.contains('sublocality') ||
                types.contains('locality') ||
                types.contains('administrative_area_level_2')) {
              return comp['long_name'];
            }
          }
        }

        // 4. Final fallback to any available formatted address
        return results.first['formatted_address'];
      }
    }

    return 'Unknown location';
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
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(16.6167, 120.3167),
              zoom: 13,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onTap: (point) async {
              final placeName = await _getPlaceNameFromLatLng(point);
              setState(() {
                _selectedPoint = point;
                _selectedDescription = placeName;
              });
            },
            markers: _selectedPoint != null
                ? {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: _selectedPoint!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      ),
                    ),
                  }
                : <Marker>{},
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),

          // Search bar and results
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() => _isSearching = true);
                      _searchPlaces(value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search location...',
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: _isSearching
                          ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchResults = [];
                                  _isSearching = false;
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 4),
                      ],
                    ),
                    constraints: BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final place = _searchResults[index];
                        return ListTile(
                          title: Text(place['description']),
                          onTap: () => _selectPlace(
                            place['place_id'],
                            place['description'],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Favorite chips
          Positioned(
            top: 96,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  ...topFavorites.map(
                    (place) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: Icon(place['icon'], size: 20),
                        label: Text(place['name']),
                        onPressed: () => _selectFavoriteLocation(
                          place['latLng'],
                          description: place['name'],
                        ),
                        backgroundColor: Colors.white,
                        shape: StadiumBorder(
                          side: BorderSide(color: theme.primaryColor),
                        ),
                        labelStyle: TextStyle(color: theme.primaryColor),
                      ),
                    ),
                  ),
                  if (moreFavorites.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: const Icon(Icons.expand_more),
                        label: const Text('More'),
                        onPressed: () =>
                            _showMoreLocationsBottomSheet(moreFavorites),
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

          // Coordinates card
          if (_selectedPoint != null)
            Positioned(
              top: 152,
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

          // My Location button
          Positioned(
            bottom: 90,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'myLocationBtn',
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _goToMyLocation,
              child: Icon(Icons.my_location, color: theme.primaryColor),
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedPoint != null
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pop(context, {
                'latLng': _selectedPoint,
                'description': _selectedDescription ?? 'Selected Location',
              }),
              backgroundColor: theme.primaryColor,
              icon: const Icon(Icons.check),
              label: const Text('Confirm'),
            )
          : null,
    );
  }
}
