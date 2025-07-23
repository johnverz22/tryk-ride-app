import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:permission_handler/permission_handler.dart';

// Domain, Data, and Provider Imports
import 'package:user/features/profile/data/models/payment_method_model.dart';
import 'package:user/features/profile/presentation/providers/payment_info_provider.dart';
import 'package:user/features/ride/domain/entities/location_entity.dart';
import 'package:user/features/ride/domain/entities/place_entity.dart';
import 'package:user/features/ride/domain/entities/ride.dart';
import 'package:user/features/ride/presentation/providers/location_picker_provider.dart';
import 'package:user/features/ride/presentation/providers/ride_booking_provider.dart';

// Screen and Widget Imports
import 'package:user/features/ride/presentation/screens/ride_tracking_screen.dart';
import 'package:user/features/ride/presentation/screens/searching_driver_screen.dart';
import 'package:user/features/ride/presentation/widgets/location_picker_screen/widgets.dart';
import 'package:user/features/ride/presentation/widgets/ride_booking_screen/modern_ride_widgets.dart';
import 'package:user/features/ride/presentation/widgets/ride_booking_screen/payment_method_card.dart';

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
  String _fromAddress = "Fetching location...";
  String _toAddress = "Where to?";
  String _selectedPaymentMethod = 'Cash';
  double? _distance;
  double? _duration;
  double? _fare;
  bool _isRouteLoading = false;
  bool _isRideRequestLoading = false;
  bool _isUsingInitialLocation = false;

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
    _initializeLocationAndMap();
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

  // --- INITIALIZATION & PERMISSIONS ---
  Future<void> _initializeLocationAndMap() async {
    setState(() => _isUsingInitialLocation = true);
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      setState(() {
        _initialCameraPosition = const CameraPosition(
          target: LatLng(14.5995, 120.9842),
          zoom: 12.0,
        );
        _fromAddress = "Permission Denied";
        _isUsingInitialLocation = false;
      });
      return;
    }
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final userLocation = LatLng(position.latitude, position.longitude);
      final address = await _getAddressFromLatLng(userLocation);
      if (mounted) {
        setState(() {
          _initialCameraPosition = CameraPosition(
            target: userLocation,
            zoom: 16.0,
          );
          _fromLocation = userLocation;
          _fromAddress = address;
        });
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(_initialCameraPosition!),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fromAddress = "Could not get location";
          _initialCameraPosition = const CameraPosition(
            target: LatLng(14.5995, 120.9842),
            zoom: 12.0,
          );
          _isUsingInitialLocation = false;
        });
      }
    }
  }

  Future<bool> _handleLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return false;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied.')),
        );
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enable location from app settings.')),
      );
      await openAppSettings();
      return false;
    }
    return true;
  }

  // --- UI STATE TRANSITIONS ---
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
        _isUsingInitialLocation = false;
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
    final bool isBooking = _currentScreenState == ScreenState.booking;

    return Scaffold(
      key: _scaffoldKey,
      appBar: isBooking
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
          _initialCameraPosition == null
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  onMapCreated: (controller) => _mapController = controller,
                  initialCameraPosition: _initialCameraPosition!,
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  padding: EdgeInsets.only(bottom: _mapBottomPadding, top: 100),
                  onCameraMove: _onCameraMove,
                  onCameraIdle: _onCameraIdle,
                ),
          if (isBooking) _buildBookingUI() else _buildLocationPickerUI(),
        ],
      ),
    );
  }

  // --- UI BUILDER WIDGETS ---
  Widget _buildBookingUI() {
    final theme = Theme.of(context);
    final areLocationsSet = _fromLocation != null && _toLocation != null;
    final double sheetHeight = areLocationsSet ? 0.6 : 0.4;
    return DraggableScrollableSheet(
      key: const ValueKey('bookingSheet'),
      initialChildSize: sheetHeight,
      minChildSize: 0.4,
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
                      onFromTap: () =>
                          _enterLocationPickingMode(ScreenState.pickingPickup),
                      onToTap: () => _enterLocationPickingMode(
                        ScreenState.pickingDestination,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (areLocationsSet) _buildRideDetailsSection(theme, ref),
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
          child: _buildPickerConfirmationPanel(theme),
        ),
      ],
    );
  }

  // --- SUB-WIDGETS FOR BOOKING UI ---
  // <<< THIS IS THE CORRECTED WIDGET >>>
  Widget _buildRideDetailsSection(ThemeData theme, WidgetRef ref) {
    final walletAsync = ref.watch(paymentInfoProvider);
    // <<< FIX: Safely access the value from the AsyncValue. Provide a fallback empty list. >>>
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
              ? _buildSearchResultsOverlay(
                  searchResults,
                  pickerState.isSearching,
                )
              : _buildFavoritesCarousel(theme),
        ),
      ],
    );
  }

  Widget _buildFavoritesCarousel(ThemeData theme) {
    final favsAsync = ref.watch(
      locationPickerProvider.select((state) => state.favoriteLocations),
    );
    return favsAsync.when(
      data: (favs) {
        if (favs.isEmpty) return const SizedBox(height: 10);
        return SizedBox(
          height: 85,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            scrollDirection: Axis.horizontal,
            itemCount: favs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final fav = favs[index];
              return SizedBox(
                width: 150,
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: InkWell(
                    onTap: () {
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(fav.latLng, 16.0),
                      );
                      ref
                          .read(locationPickerProvider.notifier)
                          .geocodeCameraPosition(fav.latLng);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(
                                fav.icon,
                                size: 22,
                                color: theme.colorScheme.primary,
                              ),
                              InkWell(
                                onTap: () => _showEditFavoriteDialog(fav),
                                child: const Padding(
                                  padding: EdgeInsets.all(4.0),
                                  child: Icon(Icons.edit_outlined, size: 18),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            fav.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 85,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox(
        height: 85,
        child: Center(child: Text("Can't load favorites")),
      ),
    );
  }

  Widget _buildSearchResultsOverlay(
    List<PlaceSuggestionEntity> results,
    bool isProviderSearching,
  ) {
    if (isProviderSearching) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 15),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 1),
          ],
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (results.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 1),
        ],
      ),
      constraints: const BoxConstraints(maxHeight: 250),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: results.length,
        itemBuilder: (context, index) {
          final suggestion = results[index];
          return ListTile(
            leading: const Icon(Icons.search),
            title: Text(suggestion.description),
            onTap: () => _onSearchResultTapped(suggestion),
          );
        },
      ),
    );
  }

  Widget _buildPickerConfirmationPanel(ThemeData theme) {
    final state = ref.watch(locationPickerProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Material(
      color: theme.scaffoldBackgroundColor,
      elevation: 8.0,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          bottomPadding > 0 ? bottomPadding : 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Set Location",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.star_border, color: Colors.grey[600]),
                  tooltip: 'Add to Favorites',
                  onPressed: _showAddFavoriteDialog,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: state.isLoadingAddress
                        ? Text(
                            "Loading...",
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.grey,
                            ),
                            key: const ValueKey('loading'),
                          )
                        : Text(
                            state.selectedDescription ??
                                "Move the map to select",
                            key: ValueKey(state.selectedDescription),
                            style: theme.textTheme.bodyLarge,
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    state.selectedPoint != null && !state.isLoadingAddress
                    ? _confirmPickedLocation
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('Confirm Location'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPERS & UTILITIES ---
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
