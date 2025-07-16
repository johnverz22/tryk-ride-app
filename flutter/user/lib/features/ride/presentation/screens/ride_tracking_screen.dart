import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'package:user/features/ride/presentation/providers/fetch_ride_details_provider.dart';
import '../../../../core/services/auth_service.dart';
import '../widgets/ride_tracking_screen/widgets.dart';

class RideTrackingScreen extends ConsumerStatefulWidget {
  final int? rideId;

  const RideTrackingScreen({required this.rideId, super.key});

  @override
  _RideTrackingScreenState createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends ConsumerState<RideTrackingScreen> {
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

  double _selectedRating = 0;
  bool _showSubmittedRating = false;
  bool _showRatingForm = false;
  bool _hasSubmittedRating = false;
  final TextEditingController _reviewController = TextEditingController();

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
      final fetchRideDetails = ref.read(fetchRideDetailsUseCaseProvider);
      final rideDetails = await fetchRideDetails(widget.rideId!);

      setState(() {
        _ride = rideDetails.ride;
        _driver = rideDetails.driver;
        _pickup = rideDetails.pickup;
        _destination = rideDetails.destination;
        _initialLoading = false;
      });

      if (rideDetails.status != 'completed') {
        _fetchDriverLocation();
        _startPolling();
      } else {
        await _updatePolylines();
      }
    } catch (e) {
      debugPrint('Error fetching ride details: $e');
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchDriverLocation();
    });
  }

  Future<void> _fetchDriverLocation() async {
    if (_ride == null) return;

    final status = _ride?['status']?['name']?.toString().toLowerCase();
    if (status == 'completed') {
      _pollingTimer?.cancel();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await AuthService().getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/api/rides/${widget.rideId}/driver-location'),
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

    if (origin == null || destination == null) {
      debugPrint(
        "Origin or destination is null: origin=$origin, dest=$destination",
      );
      return;
    }

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
                  color: Theme.of(context).colorScheme.primary,
                  width: 5,
                  points: polylineCoordinates,
                ),
              };
            });

            // 👇 Fit route in camera
            final bounds = LatLngBounds(
              southwest: LatLng(
                origin.latitude <= destination.latitude
                    ? origin.latitude
                    : destination.latitude,
                origin.longitude <= destination.longitude
                    ? origin.longitude
                    : destination.longitude,
              ),
              northeast: LatLng(
                origin.latitude >= destination.latitude
                    ? origin.latitude
                    : destination.latitude,
                origin.longitude >= destination.longitude
                    ? origin.longitude
                    : destination.longitude,
              ),
            );

            if (_mapController != null) {
              final GoogleMapController controller = _mapController!;
              controller.animateCamera(
                CameraUpdate.newLatLngBounds(bounds, 80),
              );
            }
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
        Uri.parse('$baseUrl/api/rides/cancel'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'ride_id': widget.rideId}),
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride cancelled successfully.')),
        );

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to cancel ride.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('An error occurred.')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _confirmCancelRide() {
    final rideStatus = _ride?['status']?['name'];

    if (rideStatus == 'Ride in Progress' ||
        rideStatus == 'Ride Completed Awaiting User Confirmations' ||
        rideStatus == 'Completed' ||
        rideStatus == 'Cancelled') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ride cannot be cancelled.'),
          backgroundColor: Theme.of(context).primaryColor,
        ),
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
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
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
    } else if (status == 'completed') {
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

  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a rating.')));
      return;
    }

    final rideId = widget.rideId;
    final token = await AuthService().getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/api/rides/$rideId/rate'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'rating': _selectedRating.toInt(),
        'review': _reviewController.text.trim(),
      }),
    );

    if (!mounted) return;
    if (response.statusCode == 200) {
      setState(() {
        _hasSubmittedRating = true;
        _showRatingForm = false;
        _ride?['rider_rating'] = _selectedRating;
        _ride?['rider_review'] = _reviewController.text.trim();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rating submitted!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      debugPrint('Failed to submit rating: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit rating. Please try again.'),
          backgroundColor: Colors.red,
        ),
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
          RideBottomInfo(
            ride: _ride,
            driver: _driver,
            hasSubmittedRating: _hasSubmittedRating,
            showRatingForm: _showRatingForm,
            showSubmittedRating: _showSubmittedRating,
            selectedRating: _selectedRating,
            reviewController: _reviewController,
            onRatingSelected: (rating) {
              setState(() {
                _selectedRating = rating;
              });
            },
            onSubmitRating: _submitRating,
            onCancelRatingForm: () {
              setState(() {
                _showRatingForm = false;
              });
            },
            onOpenRatingForm: () {
              setState(() {
                _showRatingForm = true;
              });
            },
            onToggleRatingCard: () {
              setState(() {
                _showSubmittedRating = !_showSubmittedRating;
              });
            },
            onToggleSubmittedRating: (value) {
              setState(() {
                _showSubmittedRating = value;
              });
            },
          ),
        ],
      ),
    );
  }
}
