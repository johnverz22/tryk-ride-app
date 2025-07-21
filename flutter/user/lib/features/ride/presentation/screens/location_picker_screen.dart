import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:user/core/utils/location_utils.dart';
import 'package:user/features/ride/domain/entities/location_entity.dart';
import 'package:user/features/ride/domain/entities/place_entity.dart';
import 'package:user/features/ride/presentation/providers/location_picker_provider.dart';
import 'package:user/features/ride/presentation/widgets/location_picker_screen/widgets.dart';
import 'package:user/providers/initial_location_provider.dart';

class LocationPickerScreen extends ConsumerStatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  ConsumerState<LocationPickerScreen> createState() =>
      _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  LatLng? _cameraMovingPosition;

  CameraPosition _currentCameraPosition = const CameraPosition(
    target: LatLng(14.5995, 120.9842), // Default to Manila
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
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

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    final initialLatLng = ref.read(initialLocationProvider).value;
    final notifier = ref.read(locationPickerProvider.notifier);

    if (initialLatLng != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(initialLatLng, 15.5),
      );
      await notifier.geocodeCameraPosition(initialLatLng);
    } else {
      await notifier.geocodeCameraPosition(_currentCameraPosition.target);
    }
  }

  void _onCameraMove(CameraPosition position) {
    if (mounted) {
      ref.read(locationPickerProvider.notifier).setLoadingState();
    }
    _cameraMovingPosition = position.target;
  }

  void _onCameraIdle() {
    if (_cameraMovingPosition != null) {
      ref
          .read(locationPickerProvider.notifier)
          .geocodeCameraPosition(_cameraMovingPosition!);
    }
  }

  void _onSearchChanged() {
    ref
        .read(locationPickerProvider.notifier)
        .searchPlaces(_searchController.text);
  }

  Future<void> _getCurrentLocationAndAnimateMap() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied.')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enable location from app settings.')),
        );
        await openAppSettings();
        return;
      }

      final Position? position =
          await LocationUtils.getCurrentPositionWithPermissionCheck(context);

      // If we successfully get a position, update the UI.
      if (position != null) {
        final LatLng currentLatLng = LatLng(
          position.latitude,
          position.longitude,
        );

        ref
            .read(locationPickerProvider.notifier)
            .geocodeCameraPosition(currentLatLng);

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(currentLatLng, 15.5),
        );
      }
    } catch (e) {
      debugPrint("Error getting current location: $e");
    }
  }

  void _showAddFavoriteDialog() {
    final state = ref.read(locationPickerProvider);
    if (state.selectedPoint != null && !state.isLoadingAddress) {
      showDialog(
        context: context,
        builder: (context) => const AddFavoriteLocationDialog(),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for the location to load before adding.'),
        ),
      );
    }
  }

  void _showEditFavoriteDialog(LocationEntity favorite) {
    showDialog(
      context: context,
      builder: (context) =>
          EditFavoriteLocationDialog(favoriteLocation: favorite),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initialLocationAsync = ref.watch(initialLocationProvider);
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // --- The Map ---
          initialLocationAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => _buildMap(theme, _currentCameraPosition),
            data: (initialLatLng) {
              _currentCameraPosition = CameraPosition(
                target: initialLatLng ?? _currentCameraPosition.target,
                zoom: initialLatLng != null
                    ? 15.5
                    : _currentCameraPosition.zoom,
              );
              return _buildMap(theme, _currentCameraPosition);
            },
          ),

          // --- Center Pin ---
          Center(
            child: Transform.translate(
              offset: const Offset(0, -25), // Adjust to align pin tip
              child: Icon(
                Icons.location_pin,
                size: 50,
                color: theme.colorScheme.primary,
                shadows: const [Shadow(color: Colors.black26, blurRadius: 10)],
              ),
            ),
          ),

          // --- Top UI Area (Search, Favorites) ---
          Positioned(
            top: topPadding,
            left: 0,
            right: 0,
            child: _buildTopUI(theme),
          ),

          // --- Bottom Confirmation Panel ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildConfirmationPanel(theme, bottomPadding),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(ThemeData theme, CameraPosition initialPosition) {
    return GoogleMap(
      initialCameraPosition: initialPosition,
      onMapCreated: _onMapCreated,
      onCameraMove: _onCameraMove,
      onCameraIdle: _onCameraIdle,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      padding: const EdgeInsets.only(
        bottom: 150, // Space for bottom panel
        top: 150, // Space for top UI
      ),
      onTap: (_) => _searchFocusNode.unfocus(),
    );
  }

  Widget _buildTopUI(ThemeData theme) {
    final state = ref.watch(locationPickerProvider);
    final searchResults = state.searchResults.value ?? [];
    final bool isSearching = _searchController.text.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFloatingSearch(theme),
        // Animate the transition between favorites and search results
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isSearching
              ? _buildSearchResultsOverlay(searchResults, state.isSearching)
              : _buildFavoritesCarousel(theme, state),
        ),
      ],
    );
  }

  Widget _buildFloatingSearch(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
      child: Material(
        elevation: 4.0,
        borderRadius: BorderRadius.circular(30.0), // More rounded
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            hintText: 'Search for a location...',
            prefixIcon: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
              color: theme.textTheme.bodySmall?.color,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(locationPickerProvider.notifier).clearSearch();
                    },
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
    );
  }

  Widget _buildFavoritesCarousel(ThemeData theme, LocationPickerState state) {
    return state.favoriteLocations.when(
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
                        CameraUpdate.newLatLngZoom(fav.latLng, 15.5),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                              // Edit button specific to this favorite
                              InkWell(
                                onTap: () => _showEditFavoriteDialog(fav),
                                child: const Padding(
                                  padding: EdgeInsets.all(
                                    4.0,
                                  ), // Makes it easier to tap
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
      loading: () => const SizedBox(height: 10),
      error: (_, __) => const SizedBox(height: 10),
    );
  }

  Widget _buildSearchResultsOverlay(
    List<PlaceSuggestionEntity> results,
    bool isSearching,
  ) {
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
      child: isSearching && results.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: results.length,
              itemBuilder: (context, index) {
                final suggestion = results[index];
                return ListTile(
                  leading: const Icon(Icons.search),
                  title: Text(suggestion.description),
                  onTap: () async {
                    _searchFocusNode.unfocus();
                    _searchController.clear();
                    final LatLng? selectedLatLng = await ref
                        .read(locationPickerProvider.notifier)
                        .selectPlace(
                          suggestion.placeId,
                          suggestion.description,
                        );

                    if (_mapController != null && selectedLatLng != null) {
                      _mapController!.animateCamera(
                        CameraUpdate.newLatLngZoom(selectedLatLng, 15.5),
                      );
                    }
                  },
                );
              },
            ),
    );
  }

  Widget _buildConfirmationPanel(ThemeData theme, double bottomPadding) {
    final state = ref.watch(locationPickerProvider);
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
                    ? () => Navigator.pop(context, {
                        'latLng': state.selectedPoint,
                        'description': state.selectedDescription,
                      })
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
}
