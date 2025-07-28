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
  // --- Controllers and Services ---
  GoogleMapController? _mapController;
  final Location _location = Location();
  final AuthService _authService = AuthService();
  final TextEditingController _reviewController = TextEditingController();

  // --- Timers ---
  Timer? _pollingTimer;
  Timer? _waitTimer;

  // --- State ---
  Map<String, dynamic>? _ride;
  LatLng? _pickup;
  LatLng? _dropoff;
  LatLng? _driverLocation;
  Set<Polyline> _polylines = {};
  bool _isLoading = true;

  // --- Ride Metrics & Status ---
  RideStatus _rideStatus = RideStatus.unknown;
  String? _distanceToDest;
  String? _etaToDest;

  // --- Waiting Timer State ---
  int _waitingSeconds = 0;
  bool _isWaitingActive = false;
  bool _waitHasBeenExtended = false;

  // --- RATING STATE FOR RIDER ---
  double _selectedRating = 0;
  bool _showRatingForm = false;
  bool _hasSubmittedRating = false;

  // --- Environment Variables ---
  String? baseUrl = dotenv.env['BASE_URL'];
  String? googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];

  // --- Core Logic (initState, dispose, API calls, etc.) ---
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
    _reviewController.dispose();
    super.dispose();
  }

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

        if (!mounted) return;

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

          // Check if driver has already rated the rider
          if (data['driver_rating'] != null) {
            _hasSubmittedRating = true;
            _selectedRating = (data['driver_rating'] as num).toDouble();
            _reviewController.text = data['driver_review'] ?? '';
          }

          if (isInitialLoad) {
            final distanceKm = data['distance_km'];
            if (distanceKm != null) {
              _distanceToDest = '$distanceKm km';
            }
            final durationMinutes = data['duration_minutes'];
            if (durationMinutes != null) {
              _etaToDest = '${durationMinutes.ceil()} min';
            }
            _isLoading = false;
          }
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
          backgroundColor: Theme.of(context).colorScheme.error,
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

  Future<void> _updateAndSendLocation(LatLng location) async {
    if (!mounted) return;

    setState(() {
      _driverLocation = location;
    });

    _mapController?.animateCamera(CameraUpdate.newLatLng(location));

    await _sendDriverLocationToServer(location);
    await _fetchRoute();
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

  Future<void> _updateRideStatus(int statusId) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/rides/${widget.rideId}/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status_id': statusId}),
      );
      if (response.statusCode == 200) {
        if (statusId == 4) {
          _waitTimer?.cancel();
          setState(() {
            _isWaitingActive = false;
            _waitingSeconds = 0;
          });
        }
        await _updateRideDetails();
      } else {
        throw Exception(
          jsonDecode(response.body)['message'] ?? 'Unknown error',
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onStartWaiting() {
    setState(() {
      _isWaitingActive = true;
      _waitingSeconds = 300;
    });
    _waitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_waitingSeconds > 0) {
        if (mounted) setState(() => _waitingSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  void _onExtendWaiting() {
    setState(() {
      _waitingSeconds += 120;
      _waitHasBeenExtended = true;
    });
  }

  Future<void> _submitRiderRating() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating.')),
      );
      return;
    }

    final token = await _authService.getToken();
    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl/api/rides/${widget.rideId}/rate-rider',
        ), // Assumed endpoint
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'rating': _selectedRating.toInt(),
          'review': _reviewController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _hasSubmittedRating = true;
          _showRatingForm = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rider rating submitted!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(
          jsonDecode(response.body)['message'] ?? 'Failed to submit rating',
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _fetchRoute() async {
    if (_driverLocation == null || googleMapsApiKey == null || !mounted) return;

    LatLng? destination;
    switch (_rideStatus) {
      case RideStatus.accepted:
      case RideStatus.driverEnRoute:
        destination = _pickup;
        break;
      case RideStatus.inProgress:
        destination = _dropoff;
        break;
      default:
        if (mounted) setState(() => _polylines = {});
        return;
    }

    if (destination == null) return;

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=${_driverLocation!.latitude},${_driverLocation!.longitude}&destination=${destination.latitude},${destination.longitude}&key=$googleMapsApiKey',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final points = data['routes'][0]['overview_polyline']['points'];
          final decodedPoints = _decodePolyline(points);
          final leg = data['routes'][0]['legs'][0];

          if (!mounted) return;
          setState(() {
            _etaToDest = leg['duration']['text'];
            _polylines = {
              Polyline(
                polylineId: const PolylineId('route'),
                points: decodedPoints,
                color: Theme.of(context).colorScheme.primary,
                width: 5,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
              ),
            };
          });
        }
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

  // --- [FINALIZED] Build Methods ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: CircleAvatar(
              backgroundColor: theme.colorScheme.surface.withOpacity(0.9),
              child: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
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
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  padding: const EdgeInsets.only(bottom: 280),
                  zoomControlsEnabled: false,
                ),
                _buildBottomPanel(),
              ],
            ),
    );
  }

  Widget _buildBottomPanel() {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.4,
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              _buildRiderHeader(),
              const SizedBox(height: 16),
              _buildTripInfoCard(),
              const SizedBox(height: 20),
              _buildActionButtons(),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRiderHeader() {
    final riderName = _ride?['user']?['name'] ?? 'Rider';
    final photoUrl = _ride?['user']?['photo_url'] as String?;
    final isPhotoValid = photoUrl != null && photoUrl.trim().isNotEmpty;
    final statusStr = _ride?['status']?['name'] ?? 'Loading...';
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: theme.colorScheme.primaryContainer,
          backgroundImage: isPhotoValid ? NetworkImage(photoUrl) : null,
          child: !isPhotoValid
              ? Icon(
                  Icons.person_rounded,
                  size: 32,
                  color: theme.colorScheme.onPrimaryContainer,
                )
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                riderName,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                statusStr,
                style: textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _contactButton(Icons.message_rounded, () {
          /* Chat */
        }),
        const SizedBox(width: 8),
        _contactButton(Icons.call_rounded, () async {
          final phoneNumber = _ride?['user']?['phone_number'];
          if (phoneNumber != null) {
            final uri = Uri.parse('tel:$phoneNumber');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          }
        }),
      ],
    );
  }

  Widget _contactButton(IconData icon, VoidCallback onPressed) {
    final theme = Theme.of(context);
    return IconButton(
      style: IconButton.styleFrom(
        backgroundColor: theme.colorScheme.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.all(12),
      ),
      icon: Icon(icon, color: theme.colorScheme.onPrimaryContainer, size: 24),
      onPressed: onPressed,
    );
  }

  Widget _buildTripInfoCard() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _infoTile(Icons.route_rounded, _distanceToDest ?? '--', 'Distance'),
          _infoTile(Icons.timer_rounded, _etaToDest ?? '--', 'ETA'),
          _infoTile(
            Icons.wallet_rounded,
            '₱${_ride?['fare_amount']?.toStringAsFixed(2) ?? '0.00'}',
            'Fare',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final theme = Theme.of(context);
    final List<Widget> actionWidgets = [];

    // Always show navigation button if the ride is active
    if (_rideStatus == RideStatus.accepted ||
        _rideStatus == RideStatus.driverEnRoute ||
        _rideStatus == RideStatus.inProgress) {
      actionWidgets.add(
        _actionButton(
          title: 'Navigate in Google Maps',
          onPressed: _navigateWithGoogleMaps,
          icon: Icons.navigation_rounded,
        ),
      );
      actionWidgets.add(const SizedBox(height: 12));
    }

    switch (_rideStatus) {
      case RideStatus.accepted:
        actionWidgets.add(
          _actionButton(
            title: "I've Arrived at Pickup",
            onPressed: () => _updateRideStatus(3),
          ),
        );
        break;

      case RideStatus.driverEnRoute:
        if (_isWaitingActive) {
          actionWidgets.add(
            Column(
              children: [
                Text('Waiting for Rider', style: theme.textTheme.titleMedium),
                Text(
                  _formatDuration(_waitingSeconds),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        title: "Start Ride",
                        onPressed: () => _updateRideStatus(4),
                      ),
                    ),
                    if (!_waitHasBeenExtended) ...[
                      const SizedBox(width: 12),
                      _actionButton(
                        title: "+2 min",
                        onPressed: _onExtendWaiting,
                        color: theme.colorScheme.tertiary,
                        textColor: theme.colorScheme.onTertiary,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        } else {
          actionWidgets.add(
            _actionButton(
              title: "Start Waiting Timer",
              onPressed: _onStartWaiting,
            ),
          );
        }
        break;

      case RideStatus.inProgress:
        actionWidgets.add(
          _actionButton(
            title: "Complete Ride",
            onPressed: () => _updateRideStatus(5),
            color: const Color(0xFF28a745),
            textColor: Colors.white,
          ),
        );
        break;

      case RideStatus.completed:
        if (_hasSubmittedRating) {
          actionWidgets.add(
            SubmittedRatingCard(
              rating: _selectedRating,
              review: _reviewController.text,
              title: "Rating Submitted",
            ),
          );
        } else if (_showRatingForm) {
          actionWidgets.add(
            RatingSection(
              isLoading:
                  false, // You can link this to a provider if you have one
              selectedRating: _selectedRating,
              reviewController: _reviewController,
              onRatingSelected: (rating) =>
                  setState(() => _selectedRating = rating),
              onSubmit: _submitRiderRating,
              title: "How was the rider?",
            ),
          );
        } else {
          // Show the "Rate Rider" button
          actionWidgets.add(
            _actionButton(
              title: "Rate Rider",
              onPressed: () => setState(() => _showRatingForm = true),
              icon: Icons.star_outline_rounded,
            ),
          );
        }
        break;

      case RideStatus.cancelled:
        actionWidgets.add(
          _statusText("Ride Cancelled", theme.colorScheme.error),
        );
        break;

      default:
        break;
    }

    return Column(children: actionWidgets);
  }

  Widget _statusText(String text, Color color) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: color,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _actionButton({
    required String title,
    required VoidCallback onPressed,
    Color? color,
    Color? textColor,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final buttonContent = icon != null
        ? [Icon(icon, size: 20), const SizedBox(width: 8), Text(title)]
        : [Text(title)];

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: color ?? theme.colorScheme.primary,
        foregroundColor: textColor ?? theme.colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        elevation: 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: buttonContent,
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    if (_driverLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'My Location'),
          anchor: const Offset(0.5, 0.5),
          flat: true,
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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateWithGoogleMaps() async {
    final LatLng? destination = _rideStatus == RideStatus.inProgress
        ? _dropoff
        : _pickup;
    if (destination == null) {
      debugPrint('Destination is null!');
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}&travelmode=driving&dir_action=navigate',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not open Google Maps.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

// --- RATING WIDGETS ---
// These can be moved to a separate file for better organization.

class SubmittedRatingCard extends StatelessWidget {
  final double rating;
  final String? review;
  final String title;

  const SubmittedRatingCard({
    super.key,
    required this.rating,
    this.review,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.green.shade600,
                size: 26,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: Colors.amber.shade600,
                    size: 36,
                  );
                }),
              ),
            ],
          ),
          if (review != null && review!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.only(left: 16),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: theme.colorScheme.primary.withOpacity(0.5),
                    width: 4.0,
                  ),
                ),
              ),
              child: Text(
                '“$review”',
                style: textTheme.bodyLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class RatingSection extends StatelessWidget {
  final bool isLoading;
  final double selectedRating;
  final TextEditingController reviewController;
  final ValueChanged<double> onRatingSelected;
  final VoidCallback onSubmit;
  final String title;

  const RatingSection({
    super.key,
    required this.isLoading,
    required this.selectedRating,
    required this.reviewController,
    required this.onRatingSelected,
    required this.onSubmit,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: () => onRatingSelected(index + 1.0),
                icon: Icon(
                  index < selectedRating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: Colors.amber,
                  size: 40,
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: reviewController,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Add a review (optional)",
            filled: true,
            fillColor: theme.scaffoldBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else
          ElevatedButton(
            onPressed: onSubmit,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: const Text("Submit Rating"),
          ),
      ],
    );
  }
}
