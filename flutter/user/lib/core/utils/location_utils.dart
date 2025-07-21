import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// A utility class for location-related functionalities.
class LocationUtils {
  /// Checks for location permissions, requests them if necessary, and returns
  /// the current device position.
  ///
  /// Shows [SnackBar] messages to the user for guidance.
  /// Returns [Position] on success, or [null] on failure.
  static Future<Position?> getCurrentPositionWithPermissionCheck(
    BuildContext context,
  ) async {
    // 1. Check if location services are enabled on the device.
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location services are disabled. Please enable them.'),
        ),
      );
      return null;
    }

    // 2. Check the current permission status.
    LocationPermission permission = await Geolocator.checkPermission();

    // 3. Handle the case where permission is denied.
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied.')),
        );
        return null;
      }
    }

    // 4. Handle the case where permission is permanently denied.
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location permissions are permanently denied. Please enable them from app settings.',
          ),
        ),
      );
      // Guide the user to the app settings.
      openAppSettings();
      return null;
    }

    // 5. If permissions are granted, get the current position.
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint("Error getting current location: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get your location: $e')),
      );
      return null;
    }
  }
}
