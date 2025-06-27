import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'map_picker_screen.dart';

class FavoriteLocationsScreen extends StatefulWidget {
  const FavoriteLocationsScreen({super.key});

  @override
  State<FavoriteLocationsScreen> createState() =>
      _FavoriteLocationsScreenState();
}

class _FavoriteLocationsScreenState extends State<FavoriteLocationsScreen> {
  final storage = const FlutterSecureStorage();
  List<dynamic> locations = [];
  bool isLoading = true;
  String? baseUrl = dotenv.env['BASE_URL'];

  @override
  void initState() {
    super.initState();
    fetchLocations();
  }

  Future<void> fetchLocations() async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No token found. Please log in again.')),
        );
        setState(() => isLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user/saved-locations'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        setState(() {
          locations = decoded is List ? decoded : [];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load locations. (${response.statusCode})'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> editLocation(Map<String, dynamic> loc) async {
    final nameController = TextEditingController(text: loc['location_name']);
    final latController = TextEditingController(
      text: loc['latitude'].toString(),
    );
    final lngController = TextEditingController(
      text: loc['longitude'].toString(),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Location'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Location Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: latController,
                decoration: const InputDecoration(labelText: 'Latitude'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lngController,
                decoration: const InputDecoration(labelText: 'Longitude'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final token = await storage.read(key: 'token');
      final response = await http.put(
        Uri.parse('$baseUrl/user/saved-locations/${loc['id']}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'location_name': nameController.text.trim(),
          'latitude': double.tryParse(latController.text),
          'longitude': double.tryParse(lngController.text),
        }),
      );

      if (response.statusCode == 200) {
        fetchLocations();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Location updated')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update (${response.statusCode})')),
        );
      }
    }
  }

  Future<void> addNewLocation() async {
    final nameController = TextEditingController();
    final latController = TextEditingController();
    final lngController = TextEditingController();

    void fillLatLng(double lat, double lng) {
      latController.text = lat.toString();
      lngController.text = lng.toString();
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add New Location'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Location Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: latController,
                decoration: const InputDecoration(labelText: 'Latitude'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lngController,
                decoration: const InputDecoration(labelText: 'Longitude'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MapPickerScreen()),
                  );
                  if (result is LatLng) {
                    fillLatLng(result.latitude, result.longitude);
                  }
                },
                icon: const Icon(Icons.map_outlined),
                label: const Text('Pick on Map'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true &&
        nameController.text.isNotEmpty &&
        latController.text.isNotEmpty &&
        lngController.text.isNotEmpty) {
      final token = await storage.read(key: 'token');
      final response = await http.post(
        Uri.parse('$baseUrl/user/saved-locations'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'location_name': nameController.text.trim(),
          'latitude': double.tryParse(latController.text),
          'longitude': double.tryParse(lngController.text),
        }),
      );

      if (response.statusCode == 201) {
        fetchLocations();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location added successfully')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to add location')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Favorite Locations')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : locations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.place_outlined,
                    size: 72,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No saved locations yet.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: addNewLocation,
                    icon: const Icon(Icons.add_location_alt),
                    label: const Text('Add Location'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: locations.length,
                    itemBuilder: (_, index) {
                      final loc = locations[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: const Icon(
                            Icons.location_pin,
                            size: 32,
                            color: Colors.redAccent,
                          ),
                          title: Text(
                            loc['location_name'],
                            style: theme.textTheme.titleMedium,
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Lat: ${loc['latitude']}, Lng: ${loc['longitude']}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.grey),
                            onPressed: () => editLocation(loc),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: addNewLocation,
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Location'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
