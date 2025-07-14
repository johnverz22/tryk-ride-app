import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? selectedLatLng;
  GoogleMapController? mapController;

  Future<LatLng> getInitialLocation() async {
    final position = await Geolocator.getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LatLng>(
      future: getInitialLocation(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        return Scaffold(
          appBar: AppBar(title: const Text('Pick Location')),
          body: GoogleMap(
            onMapCreated: (controller) => mapController = controller,
            initialCameraPosition: CameraPosition(target: snapshot.data!, zoom: 14),
            onTap: (LatLng latLng) {
              setState(() => selectedLatLng = latLng);
            },
            markers: selectedLatLng != null
                ? {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: selectedLatLng!,
                    ),
                  }
                : {},
          ),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.check),
            label: const Text('Select'),
            onPressed: selectedLatLng != null
                ? () => Navigator.pop(context, selectedLatLng)
                : null,
          ),
        );
      },
    );
  }
}
