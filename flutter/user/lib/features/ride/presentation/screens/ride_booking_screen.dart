import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:user/features/profile/data/models/payment_method_model.dart';
import 'package:user/features/ride/presentation/providers/location_picker_provider.dart';

import 'package:user/features/ride/presentation/screens/location_picker_screen.dart';
import 'package:user/features/profile/presentation/providers/payment_info_provider.dart';
import 'package:user/features/ride/domain/entities/ride.dart';
import 'package:user/features/ride/presentation/providers/ride_booking_provider.dart';
import 'package:user/features/ride/presentation/screens/ride_tracking_screen.dart';
import 'package:user/features/ride/presentation/screens/searching_driver_screen.dart';
import 'package:user/features/ride/presentation/widgets/ride_booking_screen/modern_ride_widgets.dart';
import 'package:user/features/ride/presentation/widgets/ride_booking_screen/payment_method_card.dart';

class RideBookingScreen extends ConsumerStatefulWidget {
  const RideBookingScreen({super.key});

  @override
  ConsumerState<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends ConsumerState<RideBookingScreen> {
  // Location State
  LatLng? _fromLocation;
  LatLng? _toLocation;
  String _fromAddress = "Fetching location...";
  String _toAddress = "Where to?";

  // Map State
  GoogleMapController? _mapController;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  CameraPosition? _initialCameraPosition;

  // Ride Details State
  String _selectedPaymentMethod = 'Cash';
  double? _distance;
  double? _duration;
  double? _fare;
  bool _isRouteLoading = false;
  bool _isRideRequestLoading = false;
  bool _isUsingInitialLocation = false;

  final String _googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  // Fare Constants
  static const double _baseFare = 5.0;
  static const double _perKmRate = 2.0;

  @override
  void initState() {
    super.initState();
    _initializeLocationAndMap();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  // --- HELPER FUNCTIONS ---
  Future<void> _initializeLocationAndMap() async {
    setState(() {
      _fromAddress = "Fetching location...";
      _isUsingInitialLocation =
          true; // Assume we are using it until proven otherwise
    });

    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      setState(() {
        _initialCameraPosition = const CameraPosition(
          target: LatLng(14.5995, 120.9842),
          zoom: 14.0,
        );
        _fromAddress = "Permission Denied";
        _isUsingInitialLocation = false;
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      final userLocation = LatLng(position.latitude, position.longitude);

      // --- THIS IS THE KEY CHANGE ---
      // Get the REAL address from your data source in the background
      final realAddress = await _getAddressFromLatLng(userLocation);

      // Now update the state with the real data
      if (mounted) {
        setState(() {
          _initialCameraPosition = CameraPosition(
            target: userLocation,
            zoom: 16.0,
          );
          _fromLocation = userLocation;
          _fromAddress =
              realAddress; // <-- Store the REAL address for the database
          _isUsingInitialLocation =
              true; // <-- Confirm we are at the initial location
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initialCameraPosition = const CameraPosition(
            target: LatLng(14.5995, 120.9842),
            zoom: 14.0,
          );
          _fromAddress = "Could not get location";
          _isUsingInitialLocation = false;
        });
      }
    }
  }

  Future<String> _getAddressFromLatLng(LatLng position) async {
    try {
      // Assuming you have a provider for your PlaceRemoteDataSource
      final placeDataSource = ref.read(placeRemoteDataSourceProvider);
      final geocodedAddress = await placeDataSource.getPlaceNameFromLatLng(
        position,
      );
      return geocodedAddress.formattedAddress;
    } catch (e) {
      debugPrint("Error in reverse geocoding: $e");
      // Fallback if no address is found
      return "Unnamed Road";
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location services are disabled. Please enable the services',
          ),
        ),
      );
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied')),
        );
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location permissions are permanently denied, we cannot request permissions.',
          ),
        ),
      );
      openAppSettings();
      return false;
    }
    return true;
  }

  Future<void> _selectLocation({required bool isPickup}) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );

    if (mounted && result != null && result.containsKey('latLng')) {
      setState(() {
        if (isPickup) {
          _fromLocation = result['latLng'] as LatLng;
          _fromAddress = result['description'] as String? ?? 'Selected Pickup';
        } else {
          _toLocation = result['latLng'] as LatLng;
          _toAddress =
              result['description'] as String? ?? 'Selected Destination';
        }
      });
      if (_fromLocation != null && _toLocation != null) _fetchAndDrawRoute();
    }
  }

  Future<void> _fetchAndDrawRoute() async {
    if (_fromLocation == null || _toLocation == null) return;
    setState(() => _isRouteLoading = true);

    try {
      PolylineRequest request = PolylineRequest(
        origin: PointLatLng(_fromLocation!.latitude, _fromLocation!.longitude),
        destination: PointLatLng(_toLocation!.latitude, _toLocation!.longitude),
        mode: TravelMode.driving,
      );
      PolylineResult result = await PolylinePoints().getRouteBetweenCoordinates(
        googleApiKey: _googleApiKey,
        request: request,
      );

      // --- START: CORRECTED LOGIC ---

      // 1. Check if the API request was successful and we have the necessary data
      if (result.status != 'OK' ||
          result.totalDistanceValue == null ||
          result.totalDurationValue == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Error fetching route: ${result.errorMessage ?? 'Could not get details'}",
              ),
            ),
          );
        }
        return;
      }

      final double distanceInKm = result.totalDistanceValue! / 1000.0;
      final double durationInMinutes = result.totalDurationValue! / 60.0;

      debugPrint('Start Address: ${result.startAddress}');
      debugPrint('End Address: ${result.endAddress}');
      // 3. Calculate fare based on the accurate distance
      final estimatedFare = _baseFare + (_perKmRate * distanceInKm);

      List<LatLng> polylineCoordinates = [];
      if (result.points.isNotEmpty) {
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }
      }

      if (mounted) {
        final newMarkers = <Marker>{};
        newMarkers.add(
          Marker(
            markerId: const MarkerId('pickup'),
            position: _fromLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        );
        newMarkers.add(
          Marker(markerId: const MarkerId('dropoff'), position: _toLocation!),
        );

        final newPolylines = <Polyline>{};
        newPolylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: polylineCoordinates,
            color: Theme.of(context).colorScheme.primary,
            width: 5,
          ),
        );

        setState(() {
          _distance = distanceInKm;
          _duration = durationInMinutes;
          _fare = estimatedFare;
          _markers.clear();
          _markers.addAll(newMarkers);
          _polylines.clear();
          _polylines.addAll(newPolylines);
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(
            _createLatLngBounds(_fromLocation!, _toLocation!),
            100.0,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error fetching route: $e")));
      }
    } finally {
      if (mounted) setState(() => _isRouteLoading = false);
    }
  }

  Future<void> _handleRideRequest() async {
    if (_fromLocation == null ||
        _toLocation == null ||
        _fare == null ||
        _distance == null ||
        _duration == null) {
      return;
    }
    setState(() => _isRideRequestLoading = true);

    final rideRequest = Ride(
      pickupAddress: _fromAddress,
      pickupLatitude: _fromLocation!.latitude,
      pickupLongitude: _fromLocation!.longitude,
      dropoffAddress: _toAddress,
      dropoffLatitude: _toLocation!.latitude,
      dropoffLongitude: _toLocation!.longitude,
      requestedAt: DateTime.now(),
      distanceKm: double.parse(_distance!.toStringAsFixed(2)),
      durationMinutes: _duration!,
      fareAmount: _fare!,
      paymentMethod: _selectedPaymentMethod,
      searchRadiusKm: 10,
    );

    final result = await ref.read(requestRideUseCaseProvider)(rideRequest);
    if (!mounted) return;

    setState(() => _isRideRequestLoading = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ride Request Failed: ${failure.message}'),
            backgroundColor: Colors.red,
          ),
        );
      },
      (rideId) {
        // --- THIS IS THE KEY CHANGE ---
        // Show the new, non-dismissible modal bottom sheet.
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          isDismissible: false, // Prevents closing by tapping background
          enableDrag: false, // Prevents closing by dragging
          backgroundColor:
              Colors.transparent, // Let the sheet handle its own color
          builder: (context) {
            return SearchingDriverBottomSheet(
              rideId: rideId,
              // This callback handles the final navigation step
              onRideConfirmedAndTrack: (_) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RideTrackingScreen(rideId: rideId),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showPaymentSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return PaymentSelectionSheet(
          selectedMethodId: _selectedPaymentMethod,
          onSelect: (newMethodId) {
            setState(() => _selectedPaymentMethod = newMethodId);
          },
        );
      },
    );
  }

  ({String label, IconData icon}) _getPaymentMethodDetails(
    String methodId,
    List<PaymentMethod> cards,
  ) {
    if (methodId == 'Cash') return (label: 'Cash', icon: Icons.money_rounded);
    if (methodId == 'Wallet') {
      return (label: 'Wallet', icon: Icons.account_balance_wallet_rounded);
    }
    if (methodId == 'gcash') return (label: 'GCash', icon: Icons.phone_iphone);
    if (methodId == 'maya') return (label: 'Maya', icon: Icons.shield_rounded);

    // Look for the ID in the list of fetched cards
    for (final card in cards) {
      if (card.id == methodId) {
        return (
          label: '${card.provider} •••• ${card.lastFour}',
          icon: Icons.credit_card_rounded,
        );
      }
    }

    // Fallback if no match is found (e.g., after a card is deleted)
    return (label: 'Select Payment', icon: Icons.payment_rounded);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The AppBar is now placed here for better control
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
      // extendBodyBehindAppBar makes the map draw under the app bar
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Show a loader while waiting for the initial user location
          if (_initialCameraPosition == null)
            const Center(child: CircularProgressIndicator())
          else
            GoogleMap(
              onMapCreated: (controller) => _mapController = controller,
              initialCameraPosition: _initialCameraPosition!,
              markers: _markers,
              polylines: _polylines,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height * 0.33,
              ), // Prevents UI overlap
            ),
          _buildDraggableSheet(),
        ],
      ),
    );
  }

  Widget _buildDraggableSheet() {
    final theme = Theme.of(context);
    final areLocationsSet = _fromLocation != null && _toLocation != null;
    final double targetSize = areLocationsSet ? 0.6 : 0.25;

    return DraggableScrollableSheet(
      initialChildSize: targetSize,
      minChildSize: 0.25,
      maxChildSize: targetSize,
      builder: (context, scrollController) {
        // This container now holds the entire sheet's UI
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15))],
          ),
          child: Column(
            children: [
              // Draggable Handle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              // Scrollable Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    LocationInputDisplay(
                      fromAddress: _isUsingInitialLocation
                          ? "Current Location"
                          : _fromAddress,
                      toAddress: _toAddress,
                      onFromTap: () => _selectLocation(isPickup: true),
                      onToTap: () => _selectLocation(isPickup: false),
                    ),
                    const SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: areLocationsSet
                          ? Consumer(
                              builder: (context, ref, child) {
                                return _buildRideDetailsSection(theme, ref);
                              },
                            )
                          : const SizedBox.shrink(key: ValueKey("empty")),
                    ),
                  ],
                ),
              ),
              // Sticky Bottom Button (only shown when ready to request)
              if (areLocationsSet && !_isRouteLoading)
                _buildStickyConfirmButton(theme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRideDetailsSection(ThemeData theme, WidgetRef ref) {
    final walletAsync = ref.watch(paymentInfoProvider);
    final cards = ref.watch(cardsProvider);

    if (_isRouteLoading) {
      return const Center(heightFactor: 6, child: CircularProgressIndicator());
    }

    return Column(
      key: const ValueKey('ride_details'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Trip Summary", theme),
        if (_distance != null && _duration != null && _fare != null)
          RouteInfoCard(
            distanceInMeters: _distance! * 1000,
            duration: _duration!,
            fare: _fare!,
          ),

        const SizedBox(height: 24),

        _buildSectionTitle("Payment", theme),
        walletAsync.when(
          data: (paymentInfo) {
            final paymentDetails = _getPaymentMethodDetails(
              _selectedPaymentMethod,
              cards,
            );
            return CompactPaymentMethodDisplay(
              selectedMethodLabel: paymentDetails.label,
              selectedMethodIcon: paymentDetails.icon,
              onChange: _showPaymentSelection,
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Text('Could not load payment methods.'),
        ),

        // Add some bottom padding so content doesn't abruptly end
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStickyConfirmButton(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      color: theme.scaffoldBackgroundColor,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isRideRequestLoading ? null : _handleRideRequest,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: _isRideRequestLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : const Text('Confirm Ride'),
        ),
      ),
    );
  }

  LatLngBounds _createLatLngBounds(LatLng pos1, LatLng pos2) {
    return LatLngBounds(
      southwest: LatLng(
        pos1.latitude < pos2.latitude ? pos1.latitude : pos2.latitude,
        pos1.longitude < pos2.longitude ? pos1.longitude : pos2.longitude,
      ),
      northeast: LatLng(
        pos1.latitude > pos2.latitude ? pos1.latitude : pos2.latitude,
        pos1.longitude > pos2.longitude ? pos1.longitude : pos2.longitude,
      ),
    );
  }
}
