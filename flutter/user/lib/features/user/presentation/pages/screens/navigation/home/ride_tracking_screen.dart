import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RideTrackingScreen extends StatefulWidget {
  final int? rideId;
  final LatLng? pickup;
  final LatLng? destination;

  const RideTrackingScreen({
    required this.rideId,
    required this.pickup,
    required this.destination,
    super.key,
  });

  @override
  _RideTrackingScreenState createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends State<RideTrackingScreen> {
  GoogleMapController? _mapController;
  Timer? _pollingTimer;

  LatLng? _driverLocation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.pickup == null || widget.destination == null) {
      debugPrint('Pickup or destination is null.');
      return;
    }
    _fetchDriverLocation(); // initial fetch
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchDriverLocation();
    });
  }

  Future<void> _fetchDriverLocation() async {
    setState(() => _isLoading = true);
    try {
      // Simulated driver location logic (replace with real API)
      await Future.delayed(const Duration(milliseconds: 500));
      final simulatedLatLng = LatLng(
        widget.pickup!.latitude + 0.001, // simulate movement
        widget.pickup!.longitude + 0.001,
      );

      setState(() => _driverLocation = simulatedLatLng);

      // Optional: Animate camera once driver is loaded
      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLng(_driverLocation!));
      }
    } catch (e) {
      debugPrint("Error fetching driver location: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Set<Marker> _buildMarkers() {
    final Set<Marker> markers = {
      if (widget.pickup != null)
        Marker(
          markerId: const MarkerId('pickup'),
          position: widget.pickup!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(title: 'Pickup'),
        ),
      if (widget.destination != null)
        Marker(
          markerId: const MarkerId('destination'),
          position: widget.destination!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Destination'),
        ),
    };

    if (_driverLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Driver'),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pickup == null || widget.destination == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ride Tracking')),
        body: const Center(child: Text('Missing location data.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride In Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Location',
            onPressed: _fetchDriverLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.pickup!,
              zoom: 14,
            ),
            markers: _buildMarkers(),
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
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Driver en route',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'John Doe',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Toyota Prius - ABC1234',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    // Optional call or cancel logic
                  },
                  icon: const Icon(Icons.call, size: 18),
                  label: const Text('Call'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    textStyle: const TextStyle(fontSize: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
