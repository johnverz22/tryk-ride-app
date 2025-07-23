import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

// Domain, Data, and Provider Imports
import 'package:user/features/profile/data/models/payment_method_model.dart';
import 'package:user/features/profile/presentation/providers/payment_info_provider.dart';
import 'package:user/features/ride/domain/entities/location_entity.dart';
import 'package:user/features/ride/domain/entities/place_entity.dart';
import 'package:user/features/ride/domain/entities/ride.dart';
import 'package:user/features/ride/presentation/providers/location_picker_provider.dart';
import 'package:user/features/ride/presentation/providers/location_service_provider.dart';
import 'package:user/features/ride/presentation/providers/ride_booking_provider.dart';

// Screen and Widget Imports
import 'package:user/features/ride/presentation/screens/ride_tracking_screen.dart';
import 'package:user/features/ride/presentation/screens/searching_driver_screen.dart';
import 'package:user/features/ride/presentation/widgets/ride_booking_screen/widgets.dart';

// Enum to manage the screen's current UI state
enum ScreenState { booking, pickingPickup, pickingDestination }

class RideBookingScreen extends ConsumerStatefulWidget {
  const RideBookingScreen({super.key});

  @override
  ConsumerState<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends ConsumerState<RideBookingScreen> {
  // --- UI STATE MANAGEMENT ---
  ScreenState _currentScreenState = ScreenState.booking;

  // --- MAP & LOCATION STATE ---
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  GoogleMapController? _mapController;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  CameraPosition? _initialCameraPosition;
  CameraPosition? _currentMapPosition;
  double _mapBottomPadding = 350;

  // --- RIDE BOOKING STATE ---
  LatLng? _fromLocation;
  LatLng? _toLocation;
  String _fromAddress = "Select pickup location";
  String _toAddress = "Where to?";
  String _selectedPaymentMethod = 'Cash';
  double? _distance;
  double? _duration;
  double? _fare;
  bool _isRouteLoading = false;
  bool _isRideRequestLoading = false;

  // --- LOCATION PICKER STATE ---
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // --- CONSTANTS & API KEYS ---
  final String _googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  static const double _baseFare = 5.0;
  static const double _perKmRate = 2.0;

  @override
  void initState() {
    super.initState();
    final initialLocationState = ref.read(locationServiceProvider);
    if (initialLocationState.userLocation != null) {
      _updateLocationAndAddress(initialLocationState.userLocation!);
    }
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // --- UI STATE TRANSITIONS ---
  Future<void> _updateLocationAndAddress(LatLng location) async {
    // Prevent re-fetching address if location is already set
    if (_fromLocation == location) return;

    final address = await _getAddressFromLatLng(location);
    if (mounted) {
      setState(() {
        _fromLocation = location;
        _fromAddress = address;
        // Also update the map's initial position
        _initialCameraPosition = CameraPosition(target: location, zoom: 16.0);
      });
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(_initialCameraPosition!),
      );
    }
  }

  void _enterLocationPickingMode(ScreenState targetState) {
    setState(() {
      _currentScreenState = targetState;
      _polylines.clear();
      _markers.clear();
      _mapBottomPadding = 320;
    });
    final targetLocation = (targetState == ScreenState.pickingPickup)
        ? _fromLocation
        : (_toLocation ?? _fromLocation);
    if (targetLocation != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(targetLocation, 16.0),
      );
      ref
          .read(locationPickerProvider.notifier)
          .geocodeCameraPosition(targetLocation);
    }
  }

  void _exitLocationPickingMode() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    ref.read(locationPickerProvider.notifier).clearSearch();
    setState(() {
      _currentScreenState = ScreenState.booking;
      _mapBottomPadding = 350;
    });
    if (_fromLocation != null && _toLocation != null) {
      _fetchAndDrawRoute();
    }
  }

  Future<void> _getCurrentLocationAndAnimateMap() async {
    try {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final LatLng currentLatLng = LatLng(
        position.latitude,
        position.longitude,
      );
      ref
          .read(locationPickerProvider.notifier)
          .geocodeCameraPosition(currentLatLng);
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(currentLatLng, 16.0),
      );
    } catch (e) {
      debugPrint("Error getting current location: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get current location.')),
        );
      }
    }
  }

  // --- CORE MAP & ROUTE LOGIC ---
  Future<String> _getAddressFromLatLng(LatLng position) async {
    try {
      final getPlaceNameUseCase = ref.read(
        getPlaceNameFromLatLngUseCaseProvider,
      );
      final result = await getPlaceNameUseCase(position);
      return result.fold((l) => "Unnamed Road", (r) => r.formattedAddress);
    } catch (e) {
      debugPrint("Error getting address: $e");
      return "Unnamed Road";
    }
  }

  Future<void> _fetchAndDrawRoute() async {
    if (_fromLocation == null || _toLocation == null) return;
    setState(() => _isRouteLoading = true);
    try {
      final result = await PolylinePoints().getRouteBetweenCoordinates(
        googleApiKey: _googleApiKey,
        request: PolylineRequest(
          origin: PointLatLng(
            _fromLocation!.latitude,
            _fromLocation!.longitude,
          ),
          destination: PointLatLng(
            _toLocation!.latitude,
            _toLocation!.longitude,
          ),
          mode: TravelMode.driving,
        ),
      );
      if (result.status == 'OK' && result.points.isNotEmpty) {
        final distanceInKm = (result.totalDistanceValue ?? 0) / 1000.0;
        final durationInMinutes = (result.totalDurationValue ?? 0) / 60.0;
        final estimatedFare = _baseFare + (_perKmRate * distanceInKm);
        final polylineCoordinates = result.points
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();
        if (mounted) {
          setState(() {
            _distance = distanceInKm;
            _duration = durationInMinutes;
            _fare = estimatedFare;
            _markers.clear();
            _markers.add(
              Marker(
                markerId: const MarkerId('pickup'),
                position: _fromLocation!,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
              ),
            );
            _markers.add(
              Marker(
                markerId: const MarkerId('dropoff'),
                position: _toLocation!,
              ),
            );
            _polylines.clear();
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('route'),
                points: polylineCoordinates,
                color: Theme.of(context).colorScheme.primary,
                width: 5,
              ),
            );
          });
          _mapController?.animateCamera(
            CameraUpdate.newLatLngBounds(
              _createLatLngBounds(_fromLocation!, _toLocation!),
              100.0,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Error fetching route: ${result.errorMessage ?? 'Unknown error'}",
              ),
            ),
          );
        }
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

  // --- LOCATION PICKER CALLBACKS ---
  void _onCameraMove(CameraPosition position) {
    _currentMapPosition = position;
    if (_currentScreenState != ScreenState.booking) {
      ref.read(locationPickerProvider.notifier).setLoadingState();
    }
  }

  void _onCameraIdle() {
    if (_currentScreenState != ScreenState.booking &&
        _currentMapPosition != null) {
      ref
          .read(locationPickerProvider.notifier)
          .geocodeCameraPosition(_currentMapPosition!.target);
    }
  }

  void _onSearchChanged() {
    setState(() {}); // Rebuild to update suffix icon
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      ref.read(locationPickerProvider.notifier).searchPlaces(query);
    } else {
      ref.read(locationPickerProvider.notifier).clearSearch();
    }
  }

  void _onSearchResultTapped(PlaceSuggestionEntity suggestion) async {
    _searchFocusNode.unfocus();
    final latLng = await ref
        .read(locationPickerProvider.notifier)
        .selectPlace(suggestion.placeId, suggestion.description);
    _searchController.clear();
    if (latLng != null) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16.0));
    }
  }

  void _confirmPickedLocation() {
    final pickerState = ref.read(locationPickerProvider);
    if (pickerState.selectedPoint == null ||
        pickerState.selectedDescription == null)
      return;
    setState(() {
      if (_currentScreenState == ScreenState.pickingPickup) {
        _fromLocation = pickerState.selectedPoint;
        _fromAddress = pickerState.selectedDescription!;
      } else {
        _toLocation = pickerState.selectedPoint;
        _toAddress = pickerState.selectedDescription!;
      }
    });
    _exitLocationPickingMode();
  }

  // --- RIDE REQUEST & PAYMENT ---
  Future<void> _handleRideRequest() async {
    if (_fromLocation == null || _toLocation == null || _fare == null) return;
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
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ride Request Failed: ${failure.message}'),
          backgroundColor: Colors.red,
        ),
      ),
      (rideId) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (ctx) => SearchingDriverBottomSheet(
          rideId: rideId,
          onRideConfirmedAndTrack: (_) => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => RideTrackingScreen(rideId: rideId),
            ),
          ),
        ),
      ),
    );
  }

  void _showPaymentSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => PaymentSelectionSheet(
        selectedMethodId: _selectedPaymentMethod,
        onSelect: (newMethodId) {
          setState(() => _selectedPaymentMethod = newMethodId);
        },
      ),
    );
  }

  // --- DIALOGS (for favorites) ---
  void _showAddFavoriteDialog() {
    final state = ref.read(locationPickerProvider);
    if (state.selectedPoint != null && !state.isLoadingAddress) {
      showDialog(
        context: context,
        builder: (_) => const AddFavoriteLocationDialog(),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for location to load.')),
      );
    }
  }

  void _showEditFavoriteDialog(LocationEntity favorite) {
    showDialog(
      context: context,
      builder: (_) => EditFavoriteLocationDialog(favoriteLocation: favorite),
    );
  }

  // --- MAIN BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    ref.listen<LocationState>(locationServiceProvider, (previous, next) {
      if (next.userLocation != null) {
        if (mounted) {
          _updateLocationAndAddress(next.userLocation!);
        }
      } else if (next.error != null && _initialCameraPosition == null) {
        if (mounted) {
          setState(() {
            _fromAddress = "Could not fetch location. Please select one.";
            // Set a fallback camera position so the map can load.
            _initialCameraPosition = const CameraPosition(
              target: LatLng(14.5995, 120.9842), // Manila
              zoom: 12.0,
            );
          });
        }
      }
    });

    // Watch the provider to get the current state for building the UI
    final locationState = ref.watch(locationServiceProvider);
    final bool isBooking = _currentScreenState == ScreenState.booking;
    final bool isMapReady = _initialCameraPosition != null;
    return Scaffold(
      key: _scaffoldKey,
      appBar: isBooking && isMapReady
          ? AppBar(
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
            )
          : null,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          if (isMapReady)
            GoogleMap(
              // It's now guaranteed that _initialCameraPosition is not null here.
              initialCameraPosition: _initialCameraPosition!,
              onMapCreated: (controller) => _mapController = controller,
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              padding: EdgeInsets.only(bottom: _mapBottomPadding, top: 100),
              onCameraMove: _onCameraMove,
              onCameraIdle: _onCameraIdle,
            )
          else
            // If the map isn't ready, show a centered loading spinner.
            const Center(child: CircularProgressIndicator()),

          // Only build the UI overlays (bottom sheet, picker) if the map is ready.
          if (isMapReady)
            if (isBooking)
              _buildBookingUI(locationState)
            else
              _buildLocationPickerUI(),
        ],
      ),
    );
  }

  // --- UI BUILDER WIDGETS ---
  Widget _buildBookingUI(LocationState locationState) {
    final theme = Theme.of(context);
    final areLocationsSet = _fromLocation != null && _toLocation != null;
    final double sheetHeight = areLocationsSet ? 0.6 : 0.25;

    return DraggableScrollableSheet(
      key: const ValueKey('bookingSheet'),
      initialChildSize: sheetHeight,
      minChildSize: 0.25,
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Center(
                              child: Container(
                                width: 50,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: LocationInputDisplay(
                              fromAddress:
                                  locationState.isLoading &&
                                      _fromLocation == null
                                  ? "Fetching current location..."
                                  : _fromAddress,
                              toAddress: _toAddress,
                              onFromTap: () => _enterLocationPickingMode(
                                ScreenState.pickingPickup,
                              ),
                              onToTap: () => _enterLocationPickingMode(
                                ScreenState.pickingDestination,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (areLocationsSet)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: _buildRideDetailsSection(theme, ref),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (areLocationsSet && !_isRouteLoading)
                _buildStickyConfirmButton(theme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationPickerUI() {
    final theme = Theme.of(context);
    final topPadding = MediaQuery.of(context).padding.top;
    return Stack(
      key: const ValueKey('pickerUI'),
      children: [
        Center(
          child: Transform.translate(
            offset: Offset(0, -(_mapBottomPadding / 2) + (topPadding / 2)),
            child: Icon(
              Icons.location_pin,
              size: 50,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        Positioned(
          top: topPadding,
          left: 0,
          right: 0,
          child: _buildPickerTopUI(theme),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: PickerConfirmationPanel(
            onConfirm: _confirmPickedLocation,
            onAddToFavorites: _showAddFavoriteDialog,
          ),
        ),
      ],
    );
  }

  // --- SUB-WIDGETS FOR BOOKING UI ---
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
        SectionTitle(title: "Trip Summary"),
        if (_distance != null && _duration != null && _fare != null)
          RouteInfoCard(
            distanceInMeters: _distance! * 1000,
            duration: _duration!,
            fare: _fare!,
          ),
        const SizedBox(height: 24),
        SectionTitle(title: "Payment"),
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
          error: (_, __) => const Text('Could not load payment methods.'),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStickyConfirmButton(ThemeData theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        MediaQuery.of(context).padding.bottom + 10,
      ),
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

  // --- SUB-WIDGETS FOR LOCATION PICKER UI ---
  Widget _buildPickerTopUI(ThemeData theme) {
    final pickerState = ref.watch(locationPickerProvider);
    final searchResults = pickerState.searchResults.value ?? [];
    final bool isSearching = _searchController.text.trim().isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(30.0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search for a location...',
                prefixIcon: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _exitLocationPickingMode,
                ),
                suffixIcon: isSearching
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : IconButton(
                        icon: Icon(
                          Icons.my_location,
                          color: theme.colorScheme.primary,
                        ),
                        onPressed: _getCurrentLocationAndAnimateMap,
                      ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isSearching
              ? SearchResultsOverlay(
                  results: searchResults,
                  isLoading: isSearching,
                  onSuggestionTap: _onSearchResultTapped,
                )
              : FavoritesCarousel(
                  onFavoriteTap: (favoriteLocation) {
                    // Handle the favorite location tap (e.g., animate map to the location)
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(favoriteLocation.latLng, 16.0),
                    );
                    ref
                        .read(locationPickerProvider.notifier)
                        .geocodeCameraPosition(favoriteLocation.latLng);
                  },
                  onEditTap: (favoriteLocation) {
                    // Handle the edit favorite action (e.g., open a dialog)
                    _showEditFavoriteDialog(favoriteLocation);
                  },
                ),
        ),
      ],
    );
  }

  // --- HELPERS & UTILITIES ---
  ({String label, IconData icon}) _getPaymentMethodDetails(
    String methodId,
    List<PaymentMethod> cards,
  ) {
    if (methodId == 'Cash') return (label: 'Cash', icon: Icons.money_rounded);
    if (methodId == 'Wallet')
      return (label: 'Wallet', icon: Icons.account_balance_wallet_rounded);
    if (methodId == 'gcash') return (label: 'GCash', icon: Icons.phone_iphone);
    if (methodId == 'maya') return (label: 'Maya', icon: Icons.shield_rounded);
    for (final card in cards) {
      if (card.id == methodId) {
        return (
          label: '${card.provider} •••• ${card.lastFour}',
          icon: Icons.credit_card_rounded,
        );
      }
    }
    return (label: 'Select Payment', icon: Icons.payment_rounded);
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
