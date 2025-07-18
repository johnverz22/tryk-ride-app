import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

/// A FutureProvider that attempts to get the user's current location.
/// It handles permissions and returns a LatLng or null if location cannot be obtained.
final initialLocationProvider = FutureProvider<LatLng?>((ref) async {
  try {
    // 1. Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      // Optionally, you could try to request enabling services here,
      // but it might be better handled in the UI if this provider returns null.
      return null;
    }

    // 2. Check and request location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied.');
        return null; // Permissions denied by user
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied.');
      // In a real app, you might want to show a persistent message
      // or guide the user to settings here.
      return null; // Permissions permanently denied
    }

    // 3. Get the current position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 15), // Give it a reasonable timeout
    );

    debugPrint(
      'Current location obtained: ${position.latitude}, ${position.longitude}',
    );
    return LatLng(position.latitude, position.longitude);
  } catch (e) {
    debugPrint('Error getting initial location: $e');
    // Return null on any error, so the UI can fall back to a default or error state
    return null;
  }
});
