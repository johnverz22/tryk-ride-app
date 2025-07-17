import 'dart:convert';
import 'package:flutter/material.dart'; // For debugPrint
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:user/features/core/errors/exceptions.dart';
import 'package:user/features/ride/data/models/trip_model.dart';

import '../../domain/entities/trip_entity.dart';
import 'trip_remote_datasource.dart';

class TripRemoteDataSourceImpl implements TripRemoteDataSource {
  final http.Client client;
  final String? baseUrl = dotenv.env['BASE_URL'];

  TripRemoteDataSourceImpl({required this.client});

  @override
  Future<List<TripEntity>> fetchUserTrips(String token, {int page = 1}) async {
    if (baseUrl == null) {
      debugPrint('Error: BASE_URL not configured in .env');
      throw Exception('BASE_URL not configured in .env');
    }

    final uri = Uri.parse('$baseUrl/api/user/trips?page=$page');

    try {
      // --- ADDED FOR DEBUGGING ---
      debugPrint('Attempting to fetch trips from API: $uri');
      // --- END DEBUGGING ---

      final response = await client.get(
        uri, // Use the parsed URI
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        final List<dynamic> data = responseBody['data'] ?? [];
        debugPrint('Successfully fetched ${data.length} trips for page $page.');

        return data.map((json) => TripModel.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        debugPrint('Unauthorized access: ${response.body}');
        throw UnauthorizedException('Unauthorized: ${response.body}');
      } else {
        debugPrint(
          'Failed to fetch trips: Status ${response.statusCode}, Body: ${response.body}',
        );
        throw ServerException(
          response.body, // Pass the raw body for more details
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      debugPrint('Network error fetching trips: $e');
      throw NetworkException(
        'No internet connection or server unreachable: ${e.message}',
      );
    } on FormatException catch (e) {
      debugPrint('JSON parsing error fetching trips: $e');
      debugPrint(
        'Problematic JSON body: ${e.source}',
      ); // e.source might contain the problematic string
      throw DataParsingException(
        'Failed to parse trip data: Invalid JSON format.',
      );
    } catch (e) {
      debugPrint('Unexpected error fetching trips: $e');
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
