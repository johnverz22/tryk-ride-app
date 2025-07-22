import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../../core/services/auth_service.dart';

enum RideStatus {
  accepted,
  driverEnRoute,
  inProgress,
  completed,
  cancelled,
  unknown,
}

class RideTrackingScreen extends StatefulWidget {
  final int rideId;

  const RideTrackingScreen({super.key, required this.rideId});

  @override
  State<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends State<RideTrackingScreen> {
  GoogleMapController? _mapController;
  Timer? _pollingTimer;

  Map<String, dynamic>? _ride;
  LatLng? _pickup;
  LatLng? _dropoff;
  LatLng? _driverLocation;

  Set<Polyline> _polylines = {};
  List<String> _navigationSteps = [];
  bool _isLoading = true;
  String? _distanceToDest;
  String? _etaToDest;

  String? baseUrl = dotenv.env['BASE_URL'];
  String? googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];

  int _waitingSeconds = 0;
  Timer? _waitTimer;
  bool _isWaiting = false;
  bool _extended = false;

  @override
  void initState() {
    super.initState();
    _loadRide();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _waitTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadRide();
    });
  }

  Future<void> _navigateWithGoogleMaps() async {
    // Validate locations
    if (_pickup == null || _dropoff == null) {
      debugPrint('Pickup or drop-off location is null!');
      return;
    }

    final origin = _pickup!;
    final destination = _dropoff!;

    // Log locations for debugging
    debugPrint('Origin: ${origin.latitude}, ${origin.longitude}');
    debugPrint(
      'Destination: ${destination.latitude}, ${destination.longitude}',
    );

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '&travelmode=driving'
      '&dir_action=navigate',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $uri';
    }
  }

  Future<void> _getCurrentDriverLocation() async {
    final location = Location();

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    final currentLocation = await location.getLocation();
    if (currentLocation.latitude != null && currentLocation.longitude != null) {
      final newLocation = LatLng(
        currentLocation.latitude!,
        currentLocation.longitude!,
      );

      setState(() {
        _driverLocation = newLocation;
      });

      await _sendDriverLocationToServer(newLocation);
      await _fetchRoute();
      await _centerMap();
    }
  }

  Future<void> _sendDriverLocationToServer(LatLng location) async {
    try {
      final token = await AuthService().getToken();
      await http.post(
        Uri.parse('$baseUrl/api/rides/${widget.rideId}/update-location'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'latitude': location.latitude,
          'longitude': location.longitude,
        }),
      );
    } catch (e) {
      debugPrint('Error sending driver location: $e');
    }
  }

  Future<void> _loadRide() async {
    try {
      final token = await AuthService().getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/api/rides/${widget.rideId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final pickup = LatLng(
          double.tryParse(data['pickup_latitude'].toString()) ?? 0,
          double.tryParse(data['pickup_longitude'].toString()) ?? 0,
        );
        final dropoff = LatLng(
          double.tryParse(data['dropoff_latitude'].toString()) ?? 0,
          double.tryParse(data['dropoff_longitude'].toString()) ?? 0,
        );
        final driver = LatLng(
          double.tryParse(data['driver_latitude']?.toString() ?? '0') ?? 0,
          double.tryParse(data['driver_longitude']?.toString() ?? '0') ?? 0,
        );

        setState(() {
          _ride = data;
          _pickup = pickup;
          _dropoff = dropoff;
          _driverLocation = driver;
          _isLoading = false;
        });

        final status = _getRideStatus(data['status']?['name']);
        if (status == RideStatus.completed || status == RideStatus.cancelled) {
          _pollingTimer?.cancel();
        }

        await _getCurrentDriverLocation();
        await _fetchRoute();
      } else {
        debugPrint('Failed to load ride details: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error loading ride: $e');
    }
  }

  RideStatus _getRideStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'accepted':
        return RideStatus.accepted;
      case 'driver en route':
        return RideStatus.driverEnRoute;
      case 'ride in progress':
        return RideStatus.inProgress;
      case 'completed':
        return RideStatus.completed;
      case 'cancelled':
        return RideStatus.cancelled;
      default:
        return RideStatus.unknown;
    }
  }

  Future<void> _markDriverEnRoute() async {
    try {
      final token = await AuthService().getToken();

      final response = await http.post(
        Uri.parse('$baseUrl/api/rides/${widget.rideId}/start'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status_id': 3}),
      );

      if (response.statusCode == 200) {
        await _loadRide();
      } else {
        debugPrint('Failed to mark as en route: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error marking as en route: $e');
    }
  }

  Future<void> _startRide() async {
    try {
      final token = await AuthService().getToken();

      final response = await http.post(
        Uri.parse('$baseUrl/api/rides/${widget.rideId}/start'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status_id': 4}),
      );

      if (response.statusCode == 200) {
        _waitTimer?.cancel();
        _isWaiting = false;
        _waitingSeconds = 0;

        await _loadRide();
      } else {
        debugPrint('Failed to start ride: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error starting ride: $e');
    }
  }

  Future<void> _completeRide() async {
    try {
      final token = await AuthService().getToken();

      final response = await http.post(
        Uri.parse('$baseUrl/api/rides/${widget.rideId}/complete'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status_id': 5}),
      );

      if (response.statusCode == 200) {
        await _loadRide();
      } else {
        debugPrint('Failed to complete ride: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error completing ride: $e');
    }
  }

  Future<void> _centerMap() async {
    if (_mapController != null && _driverLocation != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLng(_driverLocation!),
      );
    }
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    if (_driverLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Driver Location'),
        ),
      );
    }

    if (_pickup != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickup!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(title: 'Pickup'),
        ),
      );
    }

    if (_dropoff != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: _dropoff!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Dropoff'),
        ),
      );
    }

    return markers;
  }

  Future<void> _fetchRoute() async {
    if (_driverLocation == null || googleMapsApiKey == null) return;

    final rideStatus = _getRideStatus(_ride?['status']?['name']);
    LatLng? destination;

    switch (rideStatus) {
      case RideStatus.accepted:
      case RideStatus.driverEnRoute:
        destination = _pickup;
        break;
      case RideStatus.inProgress:
        destination = _dropoff;
        break;
      default:
        return;
    }

    if (destination == null) return;

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${_driverLocation!.latitude},${_driverLocation!.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '&key=$googleMapsApiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final points = data['routes'][0]['overview_polyline']['points'];
          final decodedPoints = _decodePolyline(points);
          final leg = data['routes'][0]['legs'][0];
          final steps = leg['steps'] as List;

          setState(() {
            _distanceToDest = leg['distance']['text'];
            _etaToDest = leg['duration']['text'];
            _navigationSteps = steps
                .map<String>((s) => _stripHtml(s['html_instructions']))
                .toList();
            _polylines = {
              Polyline(
                polylineId: const PolylineId('route'),
                points: decodedPoints,
                color: Theme.of(context).colorScheme.primary,
                width: 4,
              ),
            };
          });
        }
      } else {
        debugPrint('Failed to fetch directions: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching route: $e');
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }

  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>|&nbsp;'), '').trim();
  }

  void _startWaitingTimer() {
    _waitingSeconds = 3;
    _isWaiting = true;
    _waitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_waitingSeconds > 0) {
          _waitingSeconds--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  void _extendWaitingTime() {
    if (!_extended) {
      setState(() {
        _waitingSeconds += 120;
        _extended = true;
      });

      // Restart the timer if it was canceled
      if (_waitTimer?.isActive != true) {
        _waitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            if (_waitingSeconds > 0) {
              _waitingSeconds--;
            } else {
              timer.cancel();
            }
          });
        });
      }
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _ride == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final rider = _ride?['user']?['name'] ?? 'Unknown';
    final payment = _ride?['payment_method'] ?? 'Unknown';
    final fare = _ride?['fare_amount'] ?? 0;
    final statusStr = _ride?['status']?['name'] ?? 'Unknown';
    final rideStatus = _getRideStatus(statusStr);

    return Scaffold(
      appBar: AppBar(title: const Text('Track Ride')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _pickup ?? const LatLng(0, 0),
              zoom: 14,
            ),
            markers: _buildMarkers(),
            polylines: _polylines,
            onMapCreated: (controller) => _mapController = controller,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // Rider Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rider,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Status: $statusStr',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Address & Payment Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pickup:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(_ride?['pickup_address'] ?? 'Unknown'),
                            const SizedBox(height: 4),
                            const Text(
                              'Dropoff:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(_ride?['dropoff_address'] ?? 'Unknown'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Payment',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(payment),
                          const SizedBox(height: 4),
                          const Text(
                            'Fare',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('₱${fare.toStringAsFixed(2)}'),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Distance & ETA Tiles
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (_distanceToDest != null)
                        _infoTile(Icons.route, _distanceToDest!, 'Distance'),
                      if (_etaToDest != null)
                        _infoTile(Icons.timer, _etaToDest!, 'ETA'),
                    ],
                  ),

                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed: _navigateWithGoogleMaps,
                    icon: const Icon(Icons.navigation, color: Colors.white),
                    label: const Text(
                      'Navigate in Google Maps',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(45),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),

                  // Buttons by Ride Status
                  if (rideStatus == RideStatus.accepted)
                    ElevatedButton(
                      onPressed: _markDriverEnRoute,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(45),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Start Ride',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),

                  if (rideStatus == RideStatus.driverEnRoute && !_isWaiting)
                    ElevatedButton(
                      onPressed: _startWaitingTimer,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(45),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        "I'm Here (Wait for 5 minutes)",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),

                  if (_isWaiting && rideStatus != RideStatus.inProgress) ...[
                    Text('Waiting: ${_formatDuration(_waitingSeconds)}'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (!_extended)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _extendWaitingTime,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('+2 min Extension'),
                            ),
                          ),
                        if (!_extended &&
                            rideStatus == RideStatus.driverEnRoute)
                          const SizedBox(width: 12),
                        if (rideStatus == RideStatus.driverEnRoute)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _startRide,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text(
                                'Start Ride',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],

                  if (rideStatus == RideStatus.inProgress)
                    ElevatedButton.icon(
                      onPressed: _completeRide,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(45),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.check),
                      label: const Text('Complete Ride'),
                    ),

                  const SizedBox(height: 12),

                  if (_navigationSteps.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Directions:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ..._navigationSteps.map((s) => Text('• $s')),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
