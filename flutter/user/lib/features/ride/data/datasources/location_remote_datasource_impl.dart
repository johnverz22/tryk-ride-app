import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:user/features/core/errors/exceptions.dart';

import 'location_remote_datasource.dart';
import '../models/location_model.dart';

class LocationRemoteDataSourceImpl implements LocationRemoteDataSource {
  final http.Client client;
  final String? baseUrl = dotenv.env['BASE_URL'];

  LocationRemoteDataSourceImpl({required this.client});

  @override
  Future<List<LocationModel>> fetchSavedLocations(String token) async {
    if (baseUrl == null) throw Exception('BASE_URL not configured in .env');
    final url = Uri.parse('$baseUrl/api/user/saved-locations');
    debugPrint('Fetching saved locations from: $url');

    try {
      final response = await client.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['locations'] ?? [];
        debugPrint('Fetched ${data.length} saved locations successfully.');
        return data.map((item) => LocationModel.fromJson(item)).toList();
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Unauthorized: ${response.body}');
      } else {
        throw ServerException(response.body, statusCode: response.statusCode);
      }
    } on http.ClientException catch (e) {
      throw NetworkException('Network error: ${e.message}');
    } on FormatException catch (e) {
      throw DataParsingException(
        'Failed to parse saved locations data: ${e.message}',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  @override
  Future<LocationModel> addSavedLocation(
    String token,
    String name,
    LatLng latLng,
  ) async {
    if (baseUrl == null) throw Exception('BASE_URL not configured in .env');
    final url = Uri.parse('$baseUrl/api/user/saved-locations');
    debugPrint('Adding saved location to: $url');

    try {
      final response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'location_name': name,
          'latitude': latLng.latitude,
          'longitude': latLng.longitude,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body)['location'];
        debugPrint('Location added successfully: $responseData');
        return LocationModel.fromJson(responseData);
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Unauthorized: ${response.body}');
      } else {
        throw ServerException(response.body, statusCode: response.statusCode);
      }
    } on http.ClientException catch (e) {
      throw NetworkException('Network error: ${e.message}');
    } on FormatException catch (e) {
      throw DataParsingException(
        'Failed to parse add location response: ${e.message}',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  @override
  Future<LocationModel> updateSavedLocation(
    String token,
    int id,
    String name,
    LatLng latLng,
  ) async {
    if (baseUrl == null) throw Exception('BASE_URL not configured in .env');
    final url = Uri.parse('$baseUrl/api/user/saved-locations/$id');
    debugPrint('Updating saved location at: $url');

    try {
      final response = await client.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'location_name': name,
          'latitude': latLng.latitude,
          'longitude': latLng.longitude,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body)['location'];
        debugPrint('Location updated successfully: $responseData');
        return LocationModel.fromJson(responseData);
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Unauthorized: ${response.body}');
      } else {
        throw ServerException(response.body, statusCode: response.statusCode);
      }
    } on http.ClientException catch (e) {
      throw NetworkException('Network error: ${e.message}');
    } on FormatException catch (e) {
      throw DataParsingException(
        'Failed to parse update location response: ${e.message}',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  @override
  Future<void> deleteSavedLocation(String token, int id) async {
    if (baseUrl == null) throw Exception('BASE_URL not configured in .env');
    final url = Uri.parse('$baseUrl/api/user/saved-locations/$id');
    debugPrint('Deleting saved location at: $url');

    try {
      final response = await client.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('Location $id deleted successfully.');
        return;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Unauthorized: ${response.body}');
      } else {
        throw ServerException(response.body, statusCode: response.statusCode);
      }
    } on http.ClientException catch (e) {
      throw NetworkException('Network error: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
