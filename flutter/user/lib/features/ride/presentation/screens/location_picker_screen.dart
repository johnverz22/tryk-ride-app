import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:user/core/services/auth_service.dart';

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

  List<Map<String, dynamic>> _favoriteLocations = [];

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

  @override
  void initState() {
    super.initState();
    _loadFavoriteLocations();
  }

  Future<void> _loadFavoriteLocations() async {
    final token = await AuthService().getToken();
    final url = Uri.parse('$baseUrl/api/user/saved-locations');

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['locations'] ?? [];

        setState(() {
          _favoriteLocations = data.map<Map<String, dynamic>>((item) {
            return {
              'id': item['id'],
              'name': item['location_name'],
              'latLng': LatLng(
                double.parse(item['latitude'].toString()),
                double.parse(item['longitude'].toString()),
              ),
              'icon': Icons.star,
            };
          }).toList();
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load locations')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Connection error: $e')));
    }
  }

  void _showLocationsBottomSheet(List<Map<String, dynamic>> locations) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Favorite Locations',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),

                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: locations.length,
                    itemBuilder: (context, index) {
                      final place = locations[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: .1),
                            child: Icon(
                              place['icon'],
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          title: Text(
                            place['name'],
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert,
                              color: Theme.of(context).primaryColor,
                            ),
                            onSelected: (value) {
                              Navigator.pop(
                                context,
                              ); // close bottom sheet before dialog

                              if (value == 'edit') {
                                _showEditFavoriteDialog(index);
                              } else if (value == 'delete') {
                                _deleteFavoriteLocation(index);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),

                          onTap: () {
                            Navigator.pop(context);
                            _selectFavoriteLocation(
                              place['latLng'],
                              description: place['name'],
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _showAddFavoriteDialog();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text(
                        'Add to Favorite Locations',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddFavoriteDialog() {
    String? baseUrl = dotenv.env['BASE_URL'];
    final TextEditingController nameController = TextEditingController();
    final FocusNode focusNode = FocusNode();
    final LatLng? selectedLatLng = _selectedPoint;
    final String? selectedDescription = _selectedDescription;

    showDialog(
      context: context,
      builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          focusNode.requestFocus();
          nameController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: nameController.text.length,
          );
        });

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          title: const Text(
            'Add to Favorite Locations',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Home, Office, Coffee Spot',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                ),
              ),

              const SizedBox(height: 16),
              if (selectedLatLng == null)
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.redAccent, size: 18),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Please select a location on the map or search first.',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                )
              else
                FutureBuilder<String>(
                  future: selectedDescription != null
                      ? Future.value(selectedDescription)
                      : _getPlaceNameFromLatLng(selectedLatLng),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Row(
                        children: const [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text("Fetching location..."),
                        ],
                      );
                    }

                    final locationText = snapshot.data ?? "Unknown location";

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.place,
                            size: 20,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              locationText,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(fontSize: 15)),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final name = nameController.text.trim();

                if (name.isNotEmpty && selectedLatLng != null) {
                  final token = await AuthService().getToken();

                  final url = Uri.parse('$baseUrl/api/user/saved-locations');

                  try {
                    final response = await http.post(
                      url,
                      headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                        'Authorization': 'Bearer $token',
                      },
                      body: jsonEncode({
                        'location_name': name,
                        'latitude': selectedLatLng.latitude,
                        'longitude': selectedLatLng.longitude,
                      }),
                    );

                    if (!mounted) return;
                    if (response.statusCode == 201) {
                      Navigator.pop(context);
                      await _loadFavoriteLocations();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Location saved successfully!'),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error: ${jsonDecode(response.body)['message'] ?? 'Unknown error'}',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to connect: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('Save', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditFavoriteDialog(int index) {
    debugPrint(_favoriteLocations[index].toString());

    final favorite = _favoriteLocations[index];
    final TextEditingController nameController = TextEditingController(
      text: favorite['name'],
    );
    final FocusNode focusNode = FocusNode();

    final LatLng latLng = favorite['latLng'];
    final String? selectedDescription = _selectedDescription;

    showDialog(
      context: context,
      builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          focusNode.requestFocus();
          nameController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: nameController.text.length,
          );
        });

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          title: const Text(
            'Edit Favorite Location',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Home, Work, Gym',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<String>(
                future: selectedDescription != null
                    ? Future.value(selectedDescription)
                    : _getPlaceNameFromLatLng(latLng),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Row(
                      children: const [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text("Fetching location..."),
                      ],
                    );
                  }

                  final locationText = snapshot.data ?? "Unknown location";

                  return Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.place,
                          size: 20,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            locationText,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(fontSize: 15)),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final name = nameController.text.trim();

                if (name.isNotEmpty) {
                  final token = await AuthService().getToken();
                  final locationId = _favoriteLocations[index]['id'];
                  final LatLng? selectedLatLng = _selectedPoint;
                  final url = Uri.parse(
                    '$baseUrl/api/user/saved-locations/$locationId',
                  );
                  debugPrint(
                    'Sending updated values: $name, ${latLng.latitude}, ${latLng.longitude}',
                  );

                  try {
                    final response = await http.put(
                      url,
                      headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                        'Authorization': 'Bearer $token',
                      },
                      body: jsonEncode({
                        'location_name': name,
                        'latitude': selectedLatLng?.latitude,
                        'longitude': selectedLatLng?.longitude,
                      }),
                    );

                    if (!mounted) return;
                    if (response.statusCode == 200) {
                      final responseData = jsonDecode(response.body);

                      setState(() {
                        _favoriteLocations[index] = {
                          'id': responseData['location']['id'],
                          'name': responseData['location']['location_name'],
                          'latLng': LatLng(
                            responseData['location']['latitude'],
                            responseData['location']['longitude'],
                          ),
                          'icon': _favoriteLocations[index]['icon'],
                        };
                      });

                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Location updated successfully!'),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error: ${jsonDecode(response.body)['message'] ?? 'Unknown error'}',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to connect: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('Save', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteFavoriteLocation(int index) async {
    final locationId = _favoriteLocations[index]['id'];
    final token = await AuthService().getToken();

    final url = Uri.parse('$baseUrl/api/user/saved-locations/$locationId');

    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          _favoriteLocations.removeAt(index);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location deleted successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${jsonDecode(response.body)['message'] ?? 'Failed to delete'}',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to connect: $e')));
    }
  }

  Future<void> _goToMyLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
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

          // Favorites button
          Positioned(
            bottom: 120,
            left: 16,
            child: FloatingActionButton(
              heroTag: 'favoritesBtn',
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () {
                _showLocationsBottomSheet(_favoriteLocations);
              },
              child: Icon(Icons.favorite, color: theme.primaryColor),
            ),
          ),

          // My Location button
          Positioned(
            bottom: 120,
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
