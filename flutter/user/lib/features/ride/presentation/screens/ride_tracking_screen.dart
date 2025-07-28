import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:user/features/core/errors/failures.dart';
import 'package:user/features/ride/data/services/ride_socket_service.dart';
import 'package:user/features/ride/domain/entities/rating.dart';
import 'package:user/features/ride/presentation/providers/fetch_ride_details_provider.dart';
import 'package:user/features/ride/presentation/providers/rating_provider.dart';
import 'package:user/features/ride/presentation/providers/ride_booking_provider.dart';
import 'package:user/features/ride/presentation/providers/ride_cancellation_provider.dart';

// Enum for Ride Status (unified with driver's screen)
enum RideStatus {
  accepted,
  driverEnRoute,
  inProgress,
  completed,
  cancelled,
  unknown,
}

class RideTrackingScreen extends ConsumerStatefulWidget {
  final int rideId;

  const RideTrackingScreen({required this.rideId, super.key});

  @override
  _RideTrackingScreenState createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends ConsumerState<RideTrackingScreen> {
  // --- State & Controllers ---
  GoogleMapController? _mapController;
  late RideSocketService _socketService;
  final TextEditingController _reviewController = TextEditingController();

  // --- Ride Data ---
  Map<String, dynamic>? _ride;
  Map<String, dynamic>? _driver;
  LatLng? _pickup;
  LatLng? _destination;
  LatLng? _driverLocation;
  Set<Polyline> _polylines = {};
  bool _isLoading = true;

  // --- Ride Metrics & Status ---
  RideStatus _rideStatus = RideStatus.unknown;
  String? _distanceToDest;
  String? _etaToDest;

  // --- Rating State ---
  double _selectedRating = 0;
  bool _showRatingForm = false;
  bool _hasSubmittedRating = false;

  // --- Environment ---
  String? googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];

  // --- Lifecycle Methods ---
  @override
  void initState() {
    super.initState();
    _socketService = ref.read(rideSocketServiceProvider);
    _initializeRide();
  }

  @override
  void dispose() {
    _socketService.disconnect();
    _mapController?.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  // --- Core Logic ---
  Future<void> _initializeRide() async {
    await _fetchRideDetails();
    if (_rideStatus != RideStatus.completed &&
        _rideStatus != RideStatus.cancelled) {
      _listenToDriverLocation();
    }
  }

  Future<void> _fetchRideDetails({bool isInitialLoad = true}) async {
    if (isInitialLoad) setState(() => _isLoading = true);

    final fetchRideDetailsUseCase = ref.read(fetchRideDetailsUseCaseProvider);
    final result = await fetchRideDetailsUseCase(widget.rideId);

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() => _isLoading = false);
        _showErrorSnackBar(failure);
      },
      (rideDetails) {
        final status = _getRideStatus(rideDetails.status);

        setState(() {
          _ride = rideDetails.ride;
          _driver = rideDetails.driver;
          _pickup = rideDetails.pickup;
          _destination = rideDetails.destination;
          _rideStatus = status;

          // --- SETTING INITIAL VALUES FROM DB ---
          final distanceKm = rideDetails.ride['distance_km'];
          if (distanceKm != null) {
            _distanceToDest = '$distanceKm km';
          }
          final durationMinutes = rideDetails.ride['duration_minutes'];
          if (durationMinutes != null) {
            _etaToDest = '${durationMinutes.ceil()} min';
          }
          // --- END OF CHANGE ---

          if (_ride?['driver_latitude'] != null) {
            _driverLocation = LatLng(
              double.parse(_ride!['driver_latitude'].toString()),
              double.parse(_ride!['driver_longitude'].toString()),
            );
          }

          if (_ride?['rider_rating'] != null) {
            _hasSubmittedRating = true;
            _selectedRating = (_ride!['rider_rating'] as num).toDouble();
            _reviewController.text = _ride!['rider_review'] ?? '';
          }

          _isLoading = false;
        });

        _fetchRoute();
      },
    );
  }

  void _listenToDriverLocation() {
    _socketService.init(widget.rideId, (eventData) {
      if (!mounted) return;

      final eventName = eventData['event'] as String?;
      if (eventName == null) return;

      if (eventName.contains('DriverLocationUpdated')) {
        final payload = eventData['data'];
        final lat = double.tryParse(payload['latitude'].toString());
        final lng = double.tryParse(payload['longitude'].toString());

        if (lat != null && lng != null) {
          final newDriverLocation = LatLng(lat, lng);
          if (mounted) {
            setState(() => _driverLocation = newDriverLocation);
          }
          _fetchRoute();
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(newDriverLocation),
          );
        }
      } else if (eventName.contains('RideStatusUpdated')) {
        _fetchRideDetails(isInitialLoad: false);
      }
    });
  }

  // --- OPTIMIZED: Only fetches ETA and polyline now ---
  Future<void> _fetchRoute() async {
    if (googleMapsApiKey == null || !mounted) return;

    LatLng? origin, destination;
    switch (_rideStatus) {
      case RideStatus.accepted:
      case RideStatus.driverEnRoute:
        origin = _driverLocation;
        destination = _pickup;
        break;
      case RideStatus.inProgress:
        origin = _driverLocation;
        destination = _destination;
        break;
      case RideStatus.completed:
        origin = _pickup;
        destination = _destination;
        break;
      default:
        if (mounted) setState(() => _polylines = {});
        return;
    }

    if (origin == null || destination == null) return;

    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$googleMapsApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final points = data['routes'][0]['overview_polyline']['points'];
          final decodedPoints = _decodePolyline(points);
          final leg = data['routes'][0]['legs'][0];

          if (!mounted) return;
          setState(() {
            // ONLY ETA is updated from the API response
            _etaToDest = leg['duration']['text'];
            _polylines = {
              Polyline(
                polylineId: const PolylineId('route'),
                points: decodedPoints,
                color: Theme.of(context).colorScheme.primary,
                width: 5,
              ),
            };
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching route: $e');
    }
  }

  // --- Helpers & Utility (Unchanged) ---
  void _showErrorSnackBar(Failure failure) {
    String message;
    if (failure is ServerFailure) {
      message = failure.message;
    } else if (failure is NoInternetFailure) {
      message = 'No internet connection.';
    } else {
      message = 'An unexpected error occurred.';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
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

  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating.')),
      );
      return;
    }

    final rating = Rating(
      ratingValue: _selectedRating.toInt(),
      review: _reviewController.text.trim(),
    );

    final notifier = ref.read(rideRatingSubmissionProvider.notifier);
    await notifier.submitRating(widget.rideId, rating);

    final state = ref.read(rideRatingSubmissionProvider);
    if (mounted) {
      if (state is! AsyncError) {
        setState(() {
          _hasSubmittedRating = true;
          _showRatingForm = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rating submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit rating: ${state.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- CANCELLATION LOGIC (Unchanged) ---
  void _confirmCancelRide() {
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
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelRide() async {
    final notifier = ref.read(rideCancellationProvider.notifier);
    await notifier.cancel(widget.rideId);

    if (!mounted) return;

    final state = ref.read(rideCancellationProvider);
    if (state is! AsyncError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride cancelled successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel ride: ${state.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- Build Methods (Unchanged) ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cancellationState = ref.watch(rideCancellationProvider);
    final bool canCancel =
        _rideStatus == RideStatus.accepted ||
        _rideStatus == RideStatus.driverEnRoute;

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
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
              onTap: () => _fetchRideDetails(isInitialLoad: false),
              child: CircleAvatar(
                backgroundColor: theme.colorScheme.surface.withOpacity(0.9),
                child: Icon(Icons.refresh, color: theme.colorScheme.onSurface),
              ),
            ),
          ),
          if (canCancel)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: cancellationState is AsyncLoading
                    ? null
                    : _confirmCancelRide,
                child: CircleAvatar(
                  backgroundColor: theme.colorScheme.surface.withOpacity(0.9),
                  child: cancellationState is AsyncLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        )
                      : Icon(
                          Icons.cancel_outlined,
                          color: theme.colorScheme.error,
                        ),
                ),
              ),
            ),
        ],
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
                    target: _pickup ?? _destination ?? const LatLng(0, 0),
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
      initialChildSize: 0.3,
      minChildSize: 0.3,
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
              _buildDriverHeader(),
              const SizedBox(height: 16),
              _buildTripInfoCard(),
              const SizedBox(height: 20),
              _buildActionArea(),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDriverHeader() {
    final driverName = _driver?['name'] ?? 'Driver';
    final plateNumber = _driver?['plate'] ?? 'No vehicle info';
    final photoUrl = _driver?['photo_url'] as String?;
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
                driverName,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                plateNumber,
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
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
          final phoneNumber = _driver?['phone_number'];
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

  Widget _buildActionArea() {
    final ratingSubmissionState = ref.watch(rideRatingSubmissionProvider);
    final theme = Theme.of(context);

    if (_rideStatus == RideStatus.completed) {
      if (_hasSubmittedRating) {
        return SubmittedRatingCard(
          rating: _selectedRating,
          review: _reviewController.text,
        );
      } else if (_showRatingForm) {
        return RatingSection(
          isLoading: ratingSubmissionState is AsyncLoading,
          selectedRating: _selectedRating,
          reviewController: _reviewController,
          onRatingSelected: (rating) =>
              setState(() => _selectedRating = rating),
          onSubmit: _submitRating,
          onCancel: () => setState(() => _showRatingForm = false),
        );
      } else {
        return ElevatedButton.icon(
          onPressed: () => setState(() => _showRatingForm = true),
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
          icon: const Icon(Icons.star_outline_rounded),
          label: const Text("Rate Your Driver"),
        );
      }
    }

    if (_rideStatus == RideStatus.cancelled) {
      return _statusText("Ride Cancelled", Theme.of(context).colorScheme.error);
    }

    return const SizedBox.shrink();
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

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    if (_driverLocation != null &&
        _rideStatus != RideStatus.completed &&
        _rideStatus != RideStatus.cancelled) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'Driver'),
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
    if (_destination != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destination!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Destination'),
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
}

// --- Rating Widgets (Unchanged) ---
class SubmittedRatingCard extends StatelessWidget {
  final double rating;
  final String? review;

  const SubmittedRatingCard({super.key, required this.rating, this.review});

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
                "Rating Submitted",
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
  final VoidCallback? onCancel;

  const RatingSection({
    super.key,
    required this.isLoading,
    required this.selectedRating,
    required this.reviewController,
    required this.onRatingSelected,
    required this.onSubmit,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "How was your ride?",
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
