import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../../core/services/auth_service.dart'; // Assuming this service exists

// Enum for ride status remains the same
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
  // Controllers and Services
  GoogleMapController? _mapController;
  final Location _location = Location();
  final AuthService _authService = AuthService();

  // Timers
  Timer? _pollingTimer;
  Timer? _waitTimer;

  // State
  Map<String, dynamic>? _ride;
  LatLng? _pickup;
  LatLng? _dropoff;
  LatLng? _driverLocation;
  Set<Polyline> _polylines = {};
  bool _isLoading = true;
  List<String> _navigationSteps = [];

  // Ride Metrics & Status
  RideStatus _rideStatus = RideStatus.unknown;
  String? _distanceToDest;
  String? _etaToDest;

  // Waiting Timer State
  int _waitingSeconds = 0;
  bool _isWaitingActive = false;
  bool _waitHasBeenExtended = false;

  // Environment Variables
  String? baseUrl = dotenv.env['BASE_URL'];
  String? googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];

  @override
  void initState() {
    super.initState();
    _initializeRide();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _waitTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // --- Initialization and Polling ---
  Future<void> _initializeRide() async {
    await _updateRideDetails(isInitialLoad: true);
    if (_rideStatus != RideStatus.completed &&
        _rideStatus != RideStatus.cancelled) {
      _startPolling();
      await _startLocationUpdates();
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _updateRideDetails();
    });
  }

  // --- Core Logic: Ride and Location Updates ---
  Future<void> _updateRideDetails({bool isInitialLoad = false}) async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/rides/${widget.rideId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = _getRideStatus(data['status']?['name']);

        setState(() {
          _ride = data;
          _rideStatus = status;
          _pickup = LatLng(
            double.parse(data['pickup_latitude'].toString()),
            double.parse(data['pickup_longitude'].toString()),
          );
          _dropoff = LatLng(
            double.parse(data['dropoff_latitude'].toString()),
            double.parse(data['dropoff_longitude'].toString()),
          );

          if (data['driver_latitude'] != null) {
            _driverLocation = LatLng(
              double.parse(data['driver_latitude'].toString()),
              double.parse(data['driver_longitude'].toString()),
            );
          }

          if (isInitialLoad) _isLoading = false;
        });

        if (status == RideStatus.completed || status == RideStatus.cancelled) {
          _pollingTimer?.cancel();
        }

        await _fetchRoute();
      } else {
        throw Exception('Failed to load ride: ${response.body}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading ride details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _startLocationUpdates() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) serviceEnabled = await _location.requestService();
    if (!serviceEnabled) return;

    PermissionStatus permission = await _location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await _location.requestPermission();
    }
    if (permission != PermissionStatus.granted) return;

    // Get initial location immediately
    _updateAndSendLocation();

    // Then continue updating periodically
    _location.onLocationChanged.listen((LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        final newLocation = LatLng(
          currentLocation.latitude!,
          currentLocation.longitude!,
        );
        _updateAndSendLocation(newLocation);
      }
    });
  }

  Future<void> _updateAndSendLocation([LatLng? location]) async {
    LatLng? newLocation = location;
    if (newLocation == null) {
      final locData = await _location.getLocation();
      newLocation = LatLng(locData.latitude!, locData.longitude!);
    }

    setState(() {
      _driverLocation = newLocation;
    });
    _sendDriverLocationToServer(newLocation);
    _fetchRoute();
  }

  Future<void> _sendDriverLocationToServer(LatLng location) async {
    try {
      final token = await _authService.getToken();
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

  Future<void> _updateRideStatus(
    int statusId, {
    String? cancellationReason,
  }) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse(
          '$baseUrl/api/rides/${widget.rideId}/status',
        ), // A single endpoint is cleaner
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status_id': statusId}),
      );
      if (response.statusCode == 200) {
        // Stop waiting timer if ride starts
        if (statusId == 4) {
          // 'Ride in Progress'
          _waitTimer?.cancel();
          setState(() {
            _isWaitingActive = false;
            _waitingSeconds = 0;
          });
        }
        await _updateRideDetails(); // Refresh data after successful update
      } else {
        throw Exception(
          jsonDecode(response.body)['message'] ?? 'Unknown error',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- UI Actions ---
  void _onStartWaiting() {
    setState(() {
      _isWaitingActive = true;
      _waitingSeconds = 300; // 5 minutes
    });
    _waitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_waitingSeconds > 0) {
        setState(() => _waitingSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  void _onExtendWaiting() {
    setState(() {
      _waitingSeconds += 120; // +2 minutes
      _waitHasBeenExtended = true;
    });
  }

  // --- Map and Route Logic ---
  Future<void> _fetchRoute() async {
    // This logic remains largely the same, but it's called more efficiently now.
    if (_driverLocation == null || googleMapsApiKey == null) return;
    final rideStatus = _rideStatus;
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
        setState(() => _polylines = {});
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

  // --- Helpers ---
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

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // --- Build Methods ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading ? 'Loading Ride...' : 'Ride Tracking'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _pickup ?? const LatLng(0, 0),
                    zoom: 15,
                  ),
                  markers: _buildMarkers(),
                  polylines: _polylines,
                  onMapCreated: (controller) => _mapController = controller,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  padding: const EdgeInsets.only(
                    bottom: 250,
                  ), // Adjust padding for bottom sheet
                ),
                _buildBottomPanel(),
              ],
            ),
    );
  }

  Widget _buildBottomPanel() {
    final riderName = _ride?['user']?['name'] ?? 'Unknown';
    final statusStr = _ride?['status']?['name'] ?? 'Unknown';

    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.35,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              // Top handle
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildRiderInfo(riderName, statusStr),
              const Divider(height: 32),
              _buildTripDetails(),
              const SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRiderInfo(String name, String status) {
    return Row(
      children: [
        CircleAvatar(radius: 30, child: const Icon(Icons.person, size: 30)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Status: $status',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.message, color: Colors.blue),
          onPressed: () {
            /* TODO: Chat */
          },
        ),
        IconButton(
          icon: const Icon(Icons.call, color: Colors.green),
          onPressed: () {
            /* TODO: Call */
          },
        ),
      ],
    );
  }

  Widget _buildTripDetails() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _infoTile(Icons.route, _distanceToDest ?? '--', 'Distance'),
            _infoTile(Icons.timer, _etaToDest ?? '--', 'ETA'),
            _infoTile(
              Icons.money,
              '₱${_ride?['fare_amount']?.toStringAsFixed(2) ?? '0.00'}',
              'Fare',
            ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _navigateWithGoogleMaps,
          icon: const Icon(Icons.navigation),
          label: const Text('Navigate in Google Maps'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(45),
            backgroundColor: Colors.blue[800],
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    switch (_rideStatus) {
      case RideStatus.accepted:
        return _actionButton(
          title: "I've Arrived at Pickup",
          onPressed: () => _updateRideStatus(3),
        ); // status 3: Driver En Route

      case RideStatus.driverEnRoute:
        if (_isWaitingActive) {
          return Column(
            children: [
              Text(
                'Waiting for Rider: ${_formatDuration(_waitingSeconds)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      title: "Start Ride",
                      onPressed: () => _updateRideStatus(4),
                    ),
                  ), // status 4: In Progress
                  if (!_waitHasBeenExtended) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _actionButton(
                        title: "+2 min",
                        onPressed: _onExtendWaiting,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          );
        }
        return _actionButton(
          title: "Start Waiting Timer (5 min)",
          onPressed: _onStartWaiting,
        );

      case RideStatus.inProgress:
        return _actionButton(
          title: "Complete Ride",
          onPressed: () => _updateRideStatus(5),
          color: Colors.green,
        ); // status 5: Completed

      case RideStatus.completed:
        return const Text(
          "Ride Completed",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.green,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        );

      case RideStatus.cancelled:
        return const Text(
          "Ride Cancelled",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.red,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _actionButton({
    required String title,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(45),
        backgroundColor: color ?? Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      child: Text(title),
    );
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
}
