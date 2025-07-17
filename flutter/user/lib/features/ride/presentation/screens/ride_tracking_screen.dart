import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:user/features/core/errors/failures.dart';
import 'package:user/features/ride/data/services/ride_socket_service.dart';
import 'package:user/features/ride/presentation/providers/fetch_ride_details_provider.dart';
import 'package:user/features/ride/presentation/providers/ride_booking_provider.dart';
import 'package:user/features/ride/presentation/providers/ride_cancellation_provider.dart';
import 'package:user/features/ride/presentation/providers/rating_provider.dart';
import 'package:user/features/ride/domain/entities/rating.dart';
import 'package:user/features/ride/presentation/widgets/ride_tracking_screen/widgets.dart';

class RideTrackingScreen extends ConsumerStatefulWidget {
  final int rideId;

  const RideTrackingScreen({required this.rideId, super.key});

  @override
  _RideTrackingScreenState createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends ConsumerState<RideTrackingScreen> {
  late RideSocketService _socketService;
  GoogleMapController? _mapController;

  LatLng? _pickup;
  LatLng? _destination;
  LatLng? _driverLocation;

  Map<String, dynamic>? _ride;
  Map<String, dynamic>? _driver;

  bool _initialLoading = true;

  double _selectedRating = 0;
  bool _showSubmittedRating = false;
  bool _showRatingForm = false;
  bool _hasSubmittedRating = false;
  final TextEditingController _reviewController = TextEditingController();

  String? googleMapsApiKey = dotenv.env['Maps_API_KEY'];

  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _socketService = ref.read(rideSocketServiceProvider);
    _fetchRideDetails();
  }

  @override
  void dispose() {
    _socketService.disconnect();
    _mapController?.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _fetchRideDetails() async {
    setState(() => _initialLoading = true);

    final fetchRideDetailsUseCase = ref.read(fetchRideDetailsUseCaseProvider);

    final result = await fetchRideDetailsUseCase(widget.rideId);

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _initialLoading = false;
        });

        String errorMessage;
        if (failure is ServerFailure) {
          errorMessage = failure.message;
        } else if (failure is NoInternetFailure) {
          errorMessage = 'No internet connection. Please check your network.';
        } else if (failure is UnexpectedFailure) {
          errorMessage = failure.message;
        } else {
          errorMessage =
              'An unknown error occurred while fetching ride details.';
        }

        debugPrint('Error fetching ride details: $errorMessage');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      },
      (rideDetails) async {
        setState(() {
          _ride = rideDetails.ride;
          _driver = rideDetails.driver;
          _pickup = rideDetails.pickup;
          _destination = rideDetails.destination;
          _initialLoading = false;
          // Check if a rating already exists for this ride
          if (_ride?['rider_rating'] != null) {
            _hasSubmittedRating = true;
            _selectedRating = (_ride!['rider_rating'] as num)
                .toDouble(); // Cast to num then to Double
            _reviewController.text = _ride!['rider_review'] ?? '';
            _showSubmittedRating = true;
          }
        });

        debugPrint(
          'Ride details fetched successfully for ride ID: ${widget.rideId}',
        );
        debugPrint('Ride Status: ${rideDetails.status}');

        if (rideDetails.status != 'completed' &&
            rideDetails.status != 'cancelled') {
          _listenToDriverLocation();
        }
        await _updatePolylines();
      },
    );
  }

  void _listenToDriverLocation() {
    if (_ride == null) return;

    _socketService.disconnect();

    _socketService.init(widget.rideId, (eventData) async {
      if (!mounted) return;

      final latRaw = eventData['latitude'];
      final lngRaw = eventData['longitude'];
      final updatedDriverData = eventData['driver'] as Map<String, dynamic>?;
      final rideStatus = eventData['status']?['name']?.toString().toLowerCase();

      final lat = latRaw is num
          ? latRaw.toDouble()
          : double.tryParse(latRaw.toString()) ??
                _driverLocation?.latitude ??
                0.0;
      final lng = lngRaw is num
          ? lngRaw.toDouble()
          : double.tryParse(lngRaw.toString()) ??
                _driverLocation?.longitude ??
                0.0;

      final newDriverLatLng = LatLng(lat, lng);

      setState(() {
        _driverLocation = newDriverLatLng;
        if (updatedDriverData != null) {
          _driver = {...?_driver, ...updatedDriverData};
        }
        if (rideStatus != null) {
          _ride?['status'] = {'name': rideStatus};
        }
      });

      await _updatePolylines();
      await _recenterMap(newDriverLatLng);

      if (rideStatus == 'completed' || rideStatus == 'cancelled') {
        _socketService.disconnect();
        if (rideStatus == 'completed' && !_hasSubmittedRating) {
          setState(() {
            _showRatingForm = true;
          });
        }
      }
    });

    if (mounted) {
      setState(() {
        // _statusText = 'Tracking driver location...';
      });
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
      setState(() {
        _polylines = {};
      });
      return;
    }

    if (origin == null || destination == null) {
      debugPrint(
        "Origin or destination is null: origin=$origin, dest=$destination",
      );
      setState(() {
        _polylines = {};
      });
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

            LatLngBounds bounds;
            if (polylineCoordinates.length > 1) {
              bounds = LatLngBounds(
                southwest: LatLng(
                  polylineCoordinates
                      .map((p) => p.latitude)
                      .reduce((a, b) => a < b ? a : b),
                  polylineCoordinates
                      .map((p) => p.longitude)
                      .reduce((a, b) => a < b ? a : b),
                ),
                northeast: LatLng(
                  polylineCoordinates
                      .map((p) => p.latitude)
                      .reduce((a, b) => a > b ? a : b),
                  polylineCoordinates
                      .map((p) => p.longitude)
                      .reduce((a, b) => a > b ? a : b),
                ),
              );
            } else {
              bounds = LatLngBounds(southwest: origin, northeast: origin);
            }

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

  void _confirmCancelRide() {
    final rideStatus = _ride?['status']?['name'];

    if (rideStatus == 'Ride in Progress' ||
        rideStatus == 'Ride Completed Awaiting User Confirmations' ||
        rideStatus == 'Completed' ||
        rideStatus == 'Cancelled') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ride cannot be cancelled.'),
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

  Future<void> _cancelRide() async {
    final rideCancellationNotifier = ref.read(
      rideCancellationProvider.notifier,
    );
    await rideCancellationNotifier.cancel(widget.rideId);

    final sub = ref.listenManual(rideCancellationProvider, (previous, next) {
      if (next is AsyncData) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride cancelled successfully.')),
        );
        if (mounted) {
          setState(() {
            _ride?['status'] = {'name': 'Cancelled'};
          });
          _socketService.disconnect();
          Navigator.pop(context);
        }
      } else if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel ride: ${next.error}')),
        );
      }
    }, fireImmediately: true);

    Future.delayed(const Duration(seconds: 1), () => sub.close());
  }

  Set<Marker> _buildMarkers() {
    final Set<Marker> markers = {};
    final status = _ride?['status']?['name']?.toString().toLowerCase() ?? '';

    if (_driverLocation != null &&
        status != 'completed' &&
        status != 'cancelled') {
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

    if (_pickup != null && status != 'completed') {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickup!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
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

  @override
  Widget build(BuildContext context) {
    // Watch the rating submission state
    final ratingSubmissionState = ref.watch(rideRatingSubmissionProvider);

    final cancellationState = ref.watch(rideCancellationProvider);
    final currentRideStatus = _ride?['status']?['name']?.toLowerCase() ?? '';

    if (_initialLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ride Tracking')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final bool canCancel = ![
      'ride in progress',
      'ride completed awaiting user confirmations',
      'completed',
      'cancelled',
    ].contains(currentRideStatus);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Ride'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRideDetails,
          ),
          if (currentRideStatus != 'completed' &&
              currentRideStatus != 'cancelled')
            cancellationState is AsyncLoading
                ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.cancel),
                    onPressed: canCancel ? _confirmCancelRide : null,
                  ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target:
                  _driverLocation ??
                  _pickup ??
                  _destination ??
                  const LatLng(0, 0),
              zoom: 14,
            ),
            markers: _buildMarkers(),
            polylines: _polylines,
            onMapCreated: (controller) => _mapController = controller,
            myLocationButtonEnabled: false,
            myLocationEnabled: false,
          ),
          // Show a general loading indicator for rating submission
          if (ratingSubmissionState is AsyncLoading)
            const Positioned.fill(
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
            onSubmitRating: () async {
              if (_selectedRating == 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a rating.')),
                );
                return;
              }

              final rating = Rating(
                ratingValue: _selectedRating.toInt(),
                review: _reviewController.text.trim(),
              );

              // Call the provider's submitRating method
              await ref
                  .read(rideRatingSubmissionProvider.notifier)
                  .submitRating(widget.rideId, rating);

              // Listen for the result of the submission
              ref.listenManual(rideRatingSubmissionProvider, (previous, next) {
                if (next is AsyncData) {
                  setState(() {
                    _hasSubmittedRating = true;
                    _showRatingForm = false;
                    _ride?['rider_rating'] = _selectedRating;
                    _ride?['rider_review'] = _reviewController.text.trim();
                    _showSubmittedRating = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Rating submitted!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (next is AsyncError) {
                  debugPrint('Failed to submit rating: ${next.error}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to submit rating: ${next.error.toString()}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }, fireImmediately: true);
            },
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
