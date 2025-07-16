import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/ride_details.dart';
import '../models/ride_model.dart';

abstract class RideRemoteDatasource {
  Future<int> requestRide(RideModel model);

  Future<void> cancelRide(int rideId) async {}

  Future<RideDetails> fetchRideDetails(int rideId);
}

class RideRemoteDatasourceImpl implements RideRemoteDatasource {
  final Dio dio;

  RideRemoteDatasourceImpl(this.dio);

  @override
  Future<int> requestRide(RideModel model) async {
    final payload = model.toJson();

    final response = await dio.post('/api/rides/request', data: payload);

    // Always parse the data first, even if it's an error message
    final Map<String, dynamic>? data = response.data; // Use nullable map

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Check if the response contains the expected 'ride' and 'id'
      if (data != null &&
          data.containsKey('ride') &&
          data['ride'] is Map &&
          data['ride'].containsKey('id')) {
        return data['ride']['id'] as int;
      } else if (data != null && data.containsKey('message')) {
        // If status is 200/201 but no ride ID, and there's a 'message',
        // it's likely a business logic error from the API.
        final String? message = data['message'] as String?;
        throw Exception(
          'Ride request failed: ${message ?? 'Unknown reason, no ride ID found.'}',
        );
      } else {
        // Fallback for unexpected successful response structure
        throw Exception(
          'Ride ID not found in successful response with unexpected data format.',
        );
      }
    } else {
      // For non-200/201 status codes, try to extract an error message
      String errorMessage = 'Failed to request ride';
      if (data != null && data.containsKey('message')) {
        errorMessage = data['message'] as String;
      } else if (response.statusMessage != null) {
        errorMessage = response.statusMessage!;
      }
      throw Exception(errorMessage);
    }
  }

  @override
  Future<void> cancelRide(int rideId) async {
    await dio.post('/api/rides/cancel', data: {'ride_id': rideId});
  }

  @override
  Future<RideDetails> fetchRideDetails(int rideId) async {
    final response = await dio.get('/api/rides/$rideId');

    if (response.statusCode == 200) {
      final Map<String, dynamic> ride = (response.data as Map)
          .cast<String, dynamic>();

      final Map<String, dynamic> driver = (ride['driver'] ?? {})
          .cast<String, dynamic>();

      final pickup = LatLng(
        double.tryParse(ride['pickup_latitude'].toString()) ?? 0.0,
        double.tryParse(ride['pickup_longitude'].toString()) ?? 0.0,
      );

      final destination = LatLng(
        double.tryParse(ride['dropoff_latitude'].toString()) ?? 0.0,
        double.tryParse(ride['dropoff_longitude'].toString()) ?? 0.0,
      );

      final status =
          ride['status']?['name']?.toString().toLowerCase() ?? 'unknown';

      return RideDetails(
        ride: ride,
        driver: driver,
        pickup: pickup,
        destination: destination,
        status: status,
      );
    } else {
      throw Exception('Failed to fetch ride details: ${response.statusCode}');
    }
  }
}
