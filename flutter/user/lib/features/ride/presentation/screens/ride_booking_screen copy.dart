import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

// --- Core App Imports (Existing) ---
import 'package:user/features/core/errors/failures.dart';
import 'package:user/features/ride/presentation/providers/ride_booking_provider.dart';
import 'package:user/features/ride/presentation/screens/ride_tracking_screen.dart';
import 'package:user/features/profile/presentation/providers/payment_info_provider.dart';
import 'package:user/core/utils/geo_utils.dart';
import 'package:user/features/ride/domain/entities/ride.dart';
import 'package:user/features/ride/presentation/widgets/ride_booking_screen/widgets.dart';

// Note: Replace with your actual location picker logic if it's a separate screen/modal
Future<Map<String, dynamic>> _showLocationPicker(BuildContext context) async {
  // This is a placeholder for your location search/picker UI
  // It should return a map like: {'latLng': LatLng(...), 'description': '...'}
  await Future.delayed(const Duration(milliseconds: 500)); // Simulate selection
  return {
    'latLng': const LatLng(37.7749, -122.4194), // Example: San Francisco
    'description': '123 Main Street, San Francisco, CA',
  };
}

class RideBookingScreen extends ConsumerStatefulWidget {
  const RideBookingScreen({super.key});

  @override
  ConsumerState<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends ConsumerState<RideBookingScreen> {
  // --- STATE MANAGEMENT (EXISTING) ---
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  LatLng? _fromLocation;
  LatLng? _toLocation;
  String _selectedPaymentMethod = 'Cash';
  double _searchRadiusKm = 10;
  bool _isLoading = false;

  double? _distance;
  double? _duration;
  double? _fare;

  static const double _baseFare = 5.0;
  static const double _perKmRate = 2.0;

  // --- UI STATE ---
  final Completer<GoogleMapController> _mapController = Completer();
  PanelState _panelState = PanelState.locationInput;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _ensureLocationPermission();
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  // --- LOGIC & HANDLERS (EXISTING & ADAPTED) ---

  Future<void> _ensureLocationPermission() async {
    if (await Permission.location.request().isGranted) return;
    await openAppSettings();
  }

  Future<void> _fetchRouteInfo() async {
    if (_fromLocation == null || _toLocation == null) {
      setState(() {
        _distance = null;
        _duration = null;
        _fare = null;
        _polylines.clear();
        _panelState = PanelState.locationInput;
      });
      return;
    }

    final distance = calculateDistanceKm(
      _fromLocation!.latitude,
      _fromLocation!.longitude,
      _toLocation!.latitude,
      _toLocation!.longitude,
    );
    final duration = distance / 40 * 60;
    final fare = _baseFare + (_perKmRate * distance);

    setState(() {
      _distance = distance;
      _duration = duration;
      _fare = fare;
      _panelState = PanelState.confirmation;
      _addRoutePolyline();
    });

    _zoomToFitRoute();
  }

  void _updateMarker(String id, LatLng position, String description) {
    final marker = Marker(
      markerId: MarkerId(id),
      position: position,
      infoWindow: InfoWindow(title: description),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        id == 'from' ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueRed,
      ),
    );
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == id);
      _markers.add(marker);
    });
  }

  void _addRoutePolyline() {
    if (_fromLocation == null || _toLocation == null) return;

    final polyline = Polyline(
      polylineId: const PolylineId('route'),
      points: [_fromLocation!, _toLocation!],
      color: Theme.of(context).colorScheme.primary,
      width: 5,
    );

    setState(() {
      _polylines.add(polyline);
    });
  }

  Future<void> _zoomToFitRoute() async {
    if (_fromLocation == null || _toLocation == null) return;

    final controller = await _mapController.future;
    LatLngBounds bounds;

    if (_fromLocation!.latitude > _toLocation!.latitude) {
      bounds = LatLngBounds(southwest: _toLocation!, northeast: _fromLocation!);
    } else {
      bounds = LatLngBounds(southwest: _fromLocation!, northeast: _toLocation!);
    }

    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100.0));
  }

  void _clearLocation(String type) {
    setState(() {
      if (type == 'from') {
        _fromController.clear();
        _fromLocation = null;
        _markers.removeWhere((m) => m.markerId.value == 'from');
      } else {
        _toController.clear();
        _toLocation = null;
        _markers.removeWhere((m) => m.markerId.value == 'to');
      }
      _fetchRouteInfo(); // This will clear route info and reset panel state
    });
  }

  Future<void> _handlePayment() async {
    // This is the original _handlePayment function, with no changes to its logic.
    // It is called by the new UI's confirmation button.
    if (_fromLocation == null || _toLocation == null || _fare == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select pickup and dropoff locations.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final rideRequest = Ride(
      pickupAddress: _fromController.text,
      pickupLatitude: _fromLocation!.latitude,
      pickupLongitude: _fromLocation!.longitude,
      dropoffAddress: _toController.text,
      dropoffLatitude: _toLocation!.latitude,
      dropoffLongitude: _toLocation!.longitude,
      requestedAt: DateTime.now(),
      distanceKm: double.parse(_distance!.toStringAsFixed(2)),
      durationMinutes: double.parse(_duration!.toStringAsFixed(2)),
      fareAmount: _fare!,
      paymentMethod: _selectedPaymentMethod,
      searchRadiusKm: _searchRadiusKm.round(),
    );

    final result = await ref.read(requestRideUseCaseProvider)(rideRequest);

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() => _isLoading = false);
        String errorMessage = 'An unknown error occurred. Please try again.';
        if (failure is ServerFailure)
          errorMessage = failure.message;
        else if (failure is NoInternetFailure)
          errorMessage = 'No internet connection.';
        else if (failure is UnexpectedFailure)
          errorMessage = failure.message;
        else if (failure is UnauthorizedFailure)
          errorMessage = 'Authentication failed.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
          ),
        );
      },
      (rideId) {
        setState(() => _isLoading = false);
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => SearchingDriverBottomSheet(
            rideId: rideId,
            onDriverConfirmed: (driverInfo) {
              if (mounted) {
                Navigator.pop(context); // Dismiss searching sheet
                _showDriverConfirmedModal(
                  rideId: driverInfo.rideId,
                  driverName: driverInfo.driverName,
                  profilePicture: driverInfo.profilePicture,
                  vehicle: driverInfo.vehicle,
                );
              }
            },
          ),
        );
      },
    );
  }

  Future<void> _showDriverConfirmedModal({
    required int rideId,
    required String driverName,
    String? profilePicture,
    required String vehicle,
  }) async {
    // This function remains the same, but it will now be called after the
    // searching bottom sheet completes.
    if (!mounted) return;

    final confirmed = await showModalBottomSheet<bool?>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (bottomSheetContext) {
        return PopScope(
          canPop: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.emoji_transportation,
                  size: 48,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Driver Confirmed!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$driverName is on the way to pick you up!',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundImage: (profilePicture?.isNotEmpty ?? false)
                          ? NetworkImage(profilePicture!)
                          : null,
                      backgroundColor: Colors.grey[300],
                      child: (profilePicture == null || profilePicture.isEmpty)
                          ? const Icon(
                              Icons.person,
                              size: 36,
                              color: Colors.white,
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
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 16),
                              SizedBox(width: 4),
                              Text('4.8'), // Placeholder for driver rating
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Vehicle: $vehicle',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.track_changes),
                    label: const Text('Track Ride'),
                    onPressed: () {
                      Navigator.of(
                        bottomSheetContext,
                        rootNavigator: true,
                      ).pop(true);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RideTrackingScreen(rideId: rideId)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevent keyboard from resizing the map
      body: Stack(
        children: [
          // --- MAP BACKGROUND ---
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(
                37.42796133580664,
                -122.085749655962,
              ), // Default location
              zoom: 14,
            ),
            onMapCreated: (controller) => _mapController.complete(controller),
            markers: _markers,
            polylines: _polylines,
            padding: EdgeInsets.only(
              bottom: _panelState == PanelState.locationInput ? 280 : 400,
              top: 50,
            ),
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // --- TOP GRADIENT & APP BAR ---
          _ModernAppBar(),

          // --- SLIDING CONTROL PANEL ---
          SlidingControlPanel(
            panelState: _panelState,
            fromController: _fromController,
            toController: _toController,
            distance: _distance,
            duration: _duration,
            fare: _fare,
            searchRadius: _searchRadiusKm,
            selectedPaymentMethod: _selectedPaymentMethod,
            isLoading: _isLoading,
            onPickLocation: (type) async {
              final result = await _showLocationPicker(
                context,
              ); // Use your location picker
              final loc = result['latLng'] as LatLng?;
              final desc = result['description'] as String?;
              if (loc == null || desc == null) return;

              if (type == 'from') {
                _fromController.text = desc;
                _fromLocation = loc;
              } else {
                _toController.text = desc;
                _toLocation = loc;
              }

              _updateMarker(type, loc, desc);
              await _fetchRouteInfo();
            },
            onClearLocation: _clearLocation,
            onConfirmRide: _handlePayment,
            onRadiusChanged: (value) => setState(() => _searchRadiusKm = value),
            onPaymentChanged: (method) =>
                setState(() => _selectedPaymentMethod = method),
          ),
        ],
      ),
    );
  }
}

// --- ENUM FOR PANEL STATE ---
enum PanelState { locationInput, confirmation }

// --- CUSTOM WIDGETS (REIMAGINED UI) ---

class _ModernAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.5),
              Colors.black.withOpacity(0.0),
            ],
          ),
        ),
        child: AppBar(
          title: const Text(
            'Book a Ride',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

class SlidingControlPanel extends ConsumerWidget {
  final PanelState panelState;
  final TextEditingController fromController;
  final TextEditingController toController;
  final double? distance;
  final double? duration;
  final double? fare;
  final double searchRadius;
  final String selectedPaymentMethod;
  final bool isLoading;
  final Function(String type) onPickLocation;
  final Function(String type) onClearLocation;
  final Function() onConfirmRide;
  final ValueChanged<double> onRadiusChanged;
  final ValueChanged<String> onPaymentChanged;

  const SlidingControlPanel({
    super.key,
    required this.panelState,
    required this.fromController,
    required this.toController,
    this.distance,
    this.duration,
    this.fare,
    required this.searchRadius,
    required this.selectedPaymentMethod,
    required this.isLoading,
    required this.onPickLocation,
    required this.onClearLocation,
    required this.onConfirmRide,
    required this.onRadiusChanged,
    required this.onPaymentChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(paymentInfoProvider);

    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: panelState == PanelState.locationInput ? 280 : 420,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black26,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: panelState == PanelState.locationInput
              ? _LocationInputStage(
                  key: const ValueKey('input'),
                  fromController: fromController,
                  toController: toController,
                  onPickLocation: onPickLocation,
                  onClearLocation: onClearLocation,
                )
              : _ConfirmationStage(
                  key: const ValueKey('confirm'),
                  distance: distance,
                  duration: duration,
                  fare: fare,
                  searchRadius: searchRadius,
                  selectedPaymentMethod: selectedPaymentMethod,
                  isLoading: isLoading,
                  onConfirmRide: onConfirmRide,
                  onRadiusChanged: onRadiusChanged,
                  onPaymentChanged: onPaymentChanged,
                  walletInfo: walletAsync,
                ),
        ),
      ),
    );
  }
}

class _LocationInputStage extends StatelessWidget {
  final TextEditingController fromController;
  final TextEditingController toController;
  final Function(String type) onPickLocation;
  final Function(String type) onClearLocation;

  const _LocationInputStage({
    super.key,
    required this.fromController,
    required this.toController,
    required this.onPickLocation,
    required this.onClearLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Where are you going?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        _LocationInputField(
          controller: fromController,
          hint: 'Pickup Location',
          icon: Icons.trip_origin,
          iconColor: Colors.blueAccent,
          onTap: () => onPickLocation('from'),
          onClear: () => onClearLocation('from'),
        ),
        const SizedBox(height: 15),
        _LocationInputField(
          controller: toController,
          hint: 'Destination',
          icon: Icons.location_on,
          iconColor: Colors.redAccent,
          onTap: () => onPickLocation('to'),
          onClear: () => onClearLocation('to'),
        ),
        const Spacer(),
        Center(
          child: Text(
            'Select pickup and drop-off to see fare details.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }
}

class _LocationInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _LocationInputField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[100],
        prefixIcon: Icon(icon, color: iconColor),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(icon: const Icon(Icons.clear), onPressed: onClear)
            : null,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}

class _ConfirmationStage extends StatelessWidget {
  final double? distance;
  final double? duration;
  final double? fare;
  final double searchRadius;
  final String selectedPaymentMethod;
  final bool isLoading;
  final VoidCallback onConfirmRide;
  final ValueChanged<double> onRadiusChanged;
  final ValueChanged<String> onPaymentChanged;
  final AsyncValue<PaymentInfo> walletInfo;

  const _ConfirmationStage({
    super.key,
    this.distance,
    this.duration,
    this.fare,
    required this.searchRadius,
    required this.selectedPaymentMethod,
    required this.isLoading,
    required this.onConfirmRide,
    required this.onRadiusChanged,
    required this.onPaymentChanged,
    required this.walletInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confirm Your Ride',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        _RideInfoRow(distance: distance, duration: duration, fare: fare),
        const SizedBox(height: 15),
        const Divider(),
        _PaymentSelector(
          walletInfo: walletInfo,
          selectedMethod: selectedPaymentMethod,
          onSelect: onPaymentChanged,
        ),
        const Divider(),
        const SizedBox(height: 10),
        _RadiusSlider(radius: searchRadius, onChanged: onRadiusChanged),
        const Spacer(),
        _ConfirmButton(isLoading: isLoading, onPressed: onConfirmRide),
      ],
    );
  }
}

class _RideInfoRow extends StatelessWidget {
  final double? distance, duration, fare;
  const _RideInfoRow({this.distance, this.duration, this.fare});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _InfoChip(
          icon: Icons.social_distance,
          label: 'Distance',
          value: '${distance?.toStringAsFixed(1) ?? '...'} km',
        ),
        _InfoChip(
          icon: Icons.timer,
          label: 'Duration',
          value: '${duration?.toStringAsFixed(0) ?? '...'} min',
        ),
        _InfoChip(
          icon: Icons.price_check,
          label: 'Fare',
          value: '\$${fare?.toStringAsFixed(2) ?? '...'}',
          isHighlighted: true,
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isHighlighted;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(
          icon,
          color: isHighlighted ? theme.colorScheme.primary : Colors.grey[600],
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}

class _PaymentSelector extends StatelessWidget {
  final AsyncValue<PaymentInfo> walletInfo;
  final String selectedMethod;
  final ValueChanged<String> onSelect;

  const _PaymentSelector({
    required this.walletInfo,
    required this.selectedMethod,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return walletInfo.when(
      data: (info) => ListTile(
        leading: const Icon(Icons.payment),
        title: const Text('Payment Method'),
        trailing: DropdownButton<String>(
          value: selectedMethod,
          underline: const SizedBox(),
          items: [
            'Cash',
            'Wallet',
          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (val) => onSelect(val!),
        ),
        contentPadding: EdgeInsets.zero,
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => const Center(child: Text('Could not load payment')),
    );
  }
}

class _RadiusSlider extends StatelessWidget {
  final double radius;
  final ValueChanged<double> onChanged;

  const _RadiusSlider({required this.radius, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search Radius: ${radius.toStringAsFixed(0)} km',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Slider(
          value: radius,
          min: 1,
          max: 20,
          divisions: 19,
          label: '${radius.round()} km',
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _ConfirmButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.local_taxi),
        label: Text(isLoading ? 'Requesting...' : 'Confirm Ride'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
