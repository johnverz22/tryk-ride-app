// lib/features/ride/presentation/providers/location_service_provider.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

// 1. Define the state object (no changes here)
class LocationState {
  final LatLng? userLocation;
  final bool isLoading;
  final String? error;

  LocationState({this.userLocation, this.isLoading = false, this.error});

  LocationState copyWith({
    LatLng? userLocation,
    bool? isLoading,
    String? error,
  }) {
    return LocationState(
      userLocation: userLocation ?? this.userLocation,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// 2. Create the StateNotifier (with the fix)
class LocationServiceNotifier extends StateNotifier<LocationState> {
  LocationServiceNotifier() : super(LocationState());

  Future<void> fetchInitialLocation() async {
    // Prevent multiple fetches if one is already in progress or has succeeded.
    if (state.isLoading || state.userLocation != null) return;

    // --- THE FIX ---
    // Delay the initial 'loading' state update until after the current build cycle.
    // This prevents the "modifying a provider during build" error.
    Future.microtask(() {
      // Ensure we haven't been disposed of in the meantime
      if (mounted) {
        state = state.copyWith(isLoading: true, error: null);
      }
    });

    // The rest of the logic is asynchronous and will execute after the microtask.
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: "Location permission denied.",
        );
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      if (mounted) {
        state = state.copyWith(
          userLocation: LatLng(position.latitude, position.longitude),
          isLoading: false,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: "Could not fetch location.",
        );
      }
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await openAppSettings();
      return false;
    }
    return true;
  }
}

// 3. Define the provider (no changes here)
final locationServiceProvider =
    StateNotifierProvider<LocationServiceNotifier, LocationState>((ref) {
      return LocationServiceNotifier();
    });
