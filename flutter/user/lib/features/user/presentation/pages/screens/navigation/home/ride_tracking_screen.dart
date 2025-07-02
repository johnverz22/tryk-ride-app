import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../../../../../core/services/auth_service.dart';

class RideTrackingScreen extends StatefulWidget {
  final int? rideId;

  const RideTrackingScreen({required this.rideId, super.key});

  @override
  _RideTrackingScreenState createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends State<RideTrackingScreen> {
  String? baseUrl = dotenv.env['BASE_URL'];
  GoogleMapController? _mapController;
  Timer? _pollingTimer;

  LatLng? _pickup;
  LatLng? _destination;
  LatLng? _driverLocation;

  Map<String, dynamic>? _ride;
  Map<String, dynamic>? _driver;

  bool _isLoading = false;
  bool _initialLoading = true;

  String? googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];

  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _fetchRideDetails();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _fetchRideDetails() async {
    if (widget.rideId == null) return;

    setState(() => _initialLoading = true);

    try {
      final token = await AuthService().getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/rides/${widget.rideId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final ride = data;
        final driver = ride['driver'] ?? {};

        final pickup = LatLng(
          double.tryParse(ride['pickup_latitude'].toString()) ?? 0.0,
          double.tryParse(ride['pickup_longitude'].toString()) ?? 0.0,
        );
        final destination = LatLng(
          double.tryParse(ride['dropoff_latitude'].toString()) ?? 0.0,
          double.tryParse(ride['dropoff_longitude'].toString()) ?? 0.0,
        );

        setState(() {
          _ride = ride;
          _driver = driver;
          _pickup = pickup;
          _destination = destination;
          _initialLoading = false;
        });

        _fetchDriverLocation();
        _startPolling();
      } else {
        debugPrint('Failed to load ride: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error loading ride: $e');
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchDriverLocation();
    });
  }

  Future<void> _fetchDriverLocation() async {
    if (_ride == null) return;

    setState(() => _isLoading = true);

    try {
      final token = await AuthService().getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/rides/${widget.rideId}/driver-location'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final locationData = jsonDecode(response.body);

        final latRaw = locationData['latitude'];
        final lngRaw = locationData['longitude'];

        final lat = latRaw is num
            ? latRaw.toDouble()
            : double.tryParse(latRaw.toString()) ?? 0.0;
        final lng = lngRaw is num
            ? lngRaw.toDouble()
            : double.tryParse(lngRaw.toString()) ?? 0.0;

        final driverLatLng = LatLng(lat, lng);
        final updatedDriver = locationData['driver'] as Map<String, dynamic>?;

        setState(() {
          _driverLocation = driverLatLng;
          if (updatedDriver != null) {
            _driver = {...?_driver, ...updatedDriver};
          }
        });

        await _updatePolylines();
        await _recenterMap(driverLatLng);
      } else {
        debugPrint("Failed to fetch driver location: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching driver location: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePolylines() async {
    final status = _ride?['status']?['name']?.toString().toLowerCase().trim();

    LatLng? origin;
    LatLng? destination;

    if (_driverLocation == null) return;

    if (status == 'accepted' || status == 'driver en route') {
      origin = _driverLocation;
      destination = _pickup;
    } else if (status == 'ride in progress') {
      origin = _driverLocation;
      destination = _destination;
    } else if (status == 'completed') {
      origin = _pickup;
      destination = _destination;
    } else {
      return;
    }

    if (origin == null || destination == null) return;

    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$googleMapsApiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final polyline = data['routes'][0]['overview_polyline']['points'];

          List<PointLatLng> result = PolylinePoints().decodePolyline(polyline);

          List<LatLng> polylineCoordinates = result
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();

          if (polylineCoordinates.isNotEmpty) {
            setState(() {
              _polylines = {
                Polyline(
                  polylineId: const PolylineId('route'),
                  color: Colors.blue,
                  width: 5,
                  points: polylineCoordinates,
                ),
              };
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching directions: $e");
    }
  }

  Future<void> _recenterMap(LatLng target) async {
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 15),
        ),
      );
    }
  }

  Future<void> _cancelRide() async {
    if (widget.rideId == null) return;

    setState(() => _isLoading = true);

    try {
      final token = await AuthService().getToken();

      final response = await http.post(
        Uri.parse('$baseUrl/rides/cancel'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'ride_id': widget.rideId}),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride cancelled successfully.')),
        );

        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to cancel ride.')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('An error occurred.')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _confirmCancelRide() {
    if (_ride?['status']?['name'] == 'Ride in Progress') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot cancel after pickup.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Ride?'),
        content: const Text('Are you sure you want to cancel this ride?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelRide();
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    final Set<Marker> markers = {};
    final status = _ride?['status']['name']?.toString().toLowerCase() ?? '';

    if (_driverLocation != null && status != 'completed') {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Driver'),
        ),
      );
    }

    if (status == 'accepted' || status == 'driver en route') {
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
    } else if (status == 'ride in progress') {
      if (_destination != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('dropoff'),
            position: _destination!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: const InfoWindow(title: 'Dropoff'),
          ),
        );
      }
    }

    return markers;
  }

  Future<void> _launchGoogleMapsNavigation() async {
    final status = _ride?['status']?['name']?.toLowerCase();
    final origin = _driverLocation;
    final destination = (status == 'accepted' || status == 'driver en route')
        ? _pickup
        : (status == 'ride in progress')
        ? _destination
        : null;

    if (origin == null || destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to get navigation route')),
      );
      return;
    }

    final url =
        'https://www.google.com/maps/dir/?api=1&origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&travelmode=driving';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initialLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ride Tracking')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Ride'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRideDetails,
          ),
          IconButton(
            icon: const Icon(Icons.cancel),
            onPressed: _confirmCancelRide,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _driverLocation ?? _pickup ?? const LatLng(0, 0),
              zoom: 14,
            ),
            markers: _buildMarkers(),
            polylines: _polylines,
            onMapCreated: (controller) => _mapController = controller,
            myLocationButtonEnabled: false,
            myLocationEnabled: false,
          ),
          if (_isLoading)
            const Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(child: CircularProgressIndicator()),
            ),
          _buildBottomInfo(),
        ],
      ),
    );
  }

  Widget _buildBottomInfo() {
    try {
      final driverName = _driver?['name']?.toString() ?? 'Unknown Driver';
      final driverVehicle = _driver?['plate']?.toString() ?? 'No vehicle info';
      final rideStatus = _ride?['status']['name'].toString() ?? 'In Progress';
      final distanceKm = _ride?['distance_km'];
      final durationMin = _ride?['duration_minutes'];
      final fareAmount = _ride?['fare_amount'];
      final photoUrl = _driver?['photo_url'];
      final isPhotoValid = photoUrl is String && photoUrl.isNotEmpty;

      return Positioned(
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
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: isPhotoValid
                        ? NetworkImage(photoUrl)
                        : null,
                    backgroundColor: Colors.blueAccent,
                    child: !isPhotoValid
                        ? const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 28,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driverName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          driverVehicle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Status: $rideStatus",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () async {
                          final phoneNumber = _driver?['phone'];
                          if (phoneNumber is String && phoneNumber.isNotEmpty) {
                            final uri = Uri.parse('tel:$phoneNumber');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          }
                        },
                        icon: const Icon(Icons.phone, color: Colors.green),
                        tooltip: 'Call Driver',
                      ),
                      IconButton(
                        onPressed: () async {
                          final phoneNumber = _driver?['phone'];
                          if (phoneNumber is String && phoneNumber.isNotEmpty) {
                            final uri = Uri.parse('sms:$phoneNumber');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          }
                        },
                        icon: const Icon(Icons.message, color: Colors.blue),
                        tooltip: 'Message Driver',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (distanceKm != null)
                    _infoTile(
                      Icons.route,
                      '${distanceKm.toStringAsFixed(2)} km',
                      'Distance',
                    ),
                  if (durationMin != null)
                    _infoTile(
                      Icons.timer,
                      '${durationMin.toStringAsFixed(0)} min',
                      'ETA',
                    ),
                  if (fareAmount != null)
                    _infoTile(
                      Icons.payment,
                      '₱${fareAmount.toStringAsFixed(2)}',
                      'Fare',
                    ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _launchGoogleMapsNavigation,
                  icon: const Icon(Icons.navigation),
                  label: const Text('Open in Google Maps'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error building driver info: $e');
      return const SizedBox.shrink();
    }
  }

  Widget _infoTile(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
