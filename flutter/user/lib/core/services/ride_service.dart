import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:user/core/config/api_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RideService {
  final storage = FlutterSecureStorage();
  final client = http.Client();
  final baseUrl = ApiConfig.baseUrl;

  Future<bool> requestRide({
    required String pickupAddress,
    required double pickupLat,
    required double pickupLng,
    required String dropoffAddress,
    required double dropoffLat,
    required double dropoffLng,
  }) async {
    final token = await storage.read(key: 'token');

    if (token == null) {
      print('[RideService] No auth token');
      return false;
    }

    try {
      final response = await client.post(
        Uri.parse('$baseUrl/api/rides'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'pickup_address': pickupAddress,
          'pickup_latitude': pickupLat,
          'pickup_longitude': pickupLng,
          'dropoff_address': dropoffAddress,
          'dropoff_latitude': dropoffLat,
          'dropoff_longitude': dropoffLng,
        }),
      );

      if (response.statusCode == 201) {
        print('[RideService] Ride requested successfully');
        return true;
      } else {
        print('[RideService] Failed to request ride: ${response.body}');
        return false;
      }
    } catch (e) {
      print('[RideService] Error: $e');
      return false;
    }
  }
}
