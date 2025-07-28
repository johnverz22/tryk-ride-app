import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:user/features/core/errors/exceptions.dart';
import 'package:user/features/ride/domain/entities/ride_details.dart';
import 'package:user/features/ride/data/services/ride_socket_service.dart';

import 'ride_remote_datasource.dart';

class RideRemoteDatasourceImpl implements RideRemoteDatasource {
  final Dio dio;
  final String _googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  final RideSocketService rideSocketService;
  final PolylinePoints polylinePoints;

  RideRemoteDatasourceImpl(
    this.dio,
    this.rideSocketService,
    this.polylinePoints,
  );

  @override
  Future<int> requestRide(dynamic model) async {
    try {
      final payload = model.toJson();
      final response = await dio.post('/api/rides/request', data: payload);

      // THE FIX IS HERE: Add 202 as a valid success code.
      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        final Map<String, dynamic>? data = response.data;

        // The rest of your logic is already correct because your Laravel backend
        // still returns the ride object with its ID.
        if (data != null &&
            data.containsKey('ride') &&
            data['ride'] is Map &&
            data['ride'].containsKey('id')) {
          return data['ride']['id'] as int;
        } else {
          throw ServerException(
            data?['message'] ?? 'Unexpected response format for ride request.',
            statusCode: response.statusCode,
          );
        }
      } else {
        throw ServerException(
          response.data?['message'] ??
              response.statusMessage ??
              'Failed to request ride',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse) {
        throw ServerException(
          e.response?.data?['message'] ??
              e.response?.statusMessage ??
              'Server error during ride request',
          statusCode: e.response?.statusCode,
        );
      } else if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown) {
        throw const NetworkException(
          'No internet connection or server unreachable.',
        );
      }
      rethrow;
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  @override
  Future<void> cancelRide(int rideId) async {
    try {
      final response = await dio.post(
        '/api/rides/cancel',
        data: {'ride_id': rideId},
      );

      if (response.statusCode != 200) {
        throw ServerException(
          response.data?['message'] ??
              response.statusMessage ??
              'Failed to cancel ride',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse) {
        throw ServerException(
          e.response?.data?['message'] ??
              e.response?.statusMessage ??
              'Server error during ride cancellation',
          statusCode: e.response?.statusCode,
        );
      } else if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown) {
        throw const NetworkException(
          'No internet connection or server unreachable.',
        );
      }
      rethrow;
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  @override
  Future<RideDetails> fetchRideDetails(int rideId) async {
    try {
      final response = await dio.get('/api/rides/$rideId');

      if (response.statusCode == 200) {
        final Map<String, dynamic> ride = (response.data as Map)
            .cast<String, dynamic>();

        final Map<String, dynamic> driver = (ride['driver'] ?? {})
            .cast<String, dynamic>();

        final pickup = LatLng(
          double.tryParse(ride['pickup_latitude']?.toString() ?? '') ?? 0.0,
          double.tryParse(ride['pickup_longitude']?.toString() ?? '') ?? 0.0,
        );

        final destination = LatLng(
          double.tryParse(ride['dropoff_latitude']?.toString() ?? '') ?? 0.0,
          double.tryParse(ride['dropoff_longitude']?.toString() ?? '') ?? 0.0,
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
        throw ServerException(
          response.data?['message'] ??
              response.statusMessage ??
              'Failed to fetch ride details',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse) {
        throw ServerException(
          e.response?.data?['message'] ??
              e.response?.statusMessage ??
              'Server error fetching ride details',
          statusCode: e.response?.statusCode,
        );
      } else if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown) {
        throw const NetworkException(
          'No internet connection or server unreachable.',
        );
      }
      rethrow;
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  @override
  Future<void> submitRideRating(int rideId, int rating, String? review) async {
    try {
      final response = await dio.post(
        '/api/rides/$rideId/rate-driver',
        data: {'rating': rating, 'review': review},
      );

      if (response.statusCode != 200) {
        throw ServerException(
          response.data?['message'] ??
              response.statusMessage ??
              'Failed to submit rating',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse) {
        throw ServerException(
          e.response?.data?['message'] ??
              e.response?.statusMessage ??
              'Server error during rating submission',
          statusCode: e.response?.statusCode,
        );
      } else if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown) {
        throw const NetworkException(
          'No internet connection or server unreachable.',
        );
      }
      rethrow;
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  @override
  Stream<Map<String, dynamic>> streamRawDriverLocation(int rideId) {
    final StreamController<Map<String, dynamic>> controller =
        StreamController<Map<String, dynamic>>();

    rideSocketService.init(rideId, (eventData) {
      if (eventData is Map<String, dynamic>) {
        if (eventData.containsKey('latitude') &&
            eventData.containsKey('longitude')) {
          controller.add(eventData);
        } else {
          debugPrint(
            'RideRemoteDatasource: Received non-location event or malformed location data: $eventData',
          );
        }
      } else {
        debugPrint(
          'RideRemoteDatasource: Received non-Map eventData: $eventData',
        );
      }
    });

    controller.onCancel = () {
      debugPrint(
        'RideRemoteDatasource: Driver location stream cancelled. Disconnecting socket...',
      );
      rideSocketService.disconnect();
      controller.close();
    };

    return controller.stream;
  }

  @override
  Future<PolylineResult> getPolylineRoute(LatLng from, LatLng to) async {
    final result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: _googleApiKey,
      request: PolylineRequest(
        origin: PointLatLng(from.latitude, from.longitude),
        destination: PointLatLng(to.latitude, to.longitude),
        mode: TravelMode.driving,
      ),
    );

    if (result.status == 'OK') {
      return result;
    } else {
      throw ServerException(result.errorMessage ?? 'Failed to get route');
    }
  }
}
