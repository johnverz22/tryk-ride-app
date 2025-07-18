import 'dart:convert';
import 'package:flutter/material.dart'; // For debugPrint
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:user/features/core/errors/exceptions.dart';

import 'place_remote_datasource.dart';
import '../models/place_details_model.dart';
import '../models/place_suggestion_model.dart';
import '../models/geocoded_address_model.dart';

class PlaceRemoteDataSourceImpl implements PlaceRemoteDataSource {
  final http.Client client;
  final String? googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];

  PlaceRemoteDataSourceImpl({required this.client});

  void _checkApiKey() {
    if (googleMapsApiKey == null) {
      throw Exception('GOOGLE_MAPS_API_KEY not configured in .env');
    }
  }

  @override
  Future<List<PlaceSuggestionModel>> searchPlaces(String query) async {
    _checkApiKey();
    if (query.isEmpty) return [];

    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$googleMapsApiKey&components=country:ph';
    debugPrint('Searching places: $url');

    try {
      final response = await client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> predictions = data['predictions'] ?? [];
        debugPrint('Found ${predictions.length} place suggestions.');
        return predictions
            .map((json) => PlaceSuggestionModel.fromJson(json))
            .toList();
      } else {
        throw ServerException(response.body, statusCode: response.statusCode);
      }
    } on http.ClientException catch (e) {
      throw NetworkException('Network error searching places: ${e.message}');
    } on FormatException catch (e) {
      throw DataParsingException(
        'Failed to parse place search response: ${e.message}',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  @override
  Future<PlaceDetailsModel> getPlaceDetails(String placeId) async {
    _checkApiKey();
    final url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$googleMapsApiKey';
    debugPrint('Fetching place details for $placeId: $url');

    try {
      final response = await client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['result'] != null) {
          debugPrint('Place details fetched successfully for $placeId.');
          return PlaceDetailsModel.fromJson(data['result']);
        } else {
          throw ServerException(
            'Place details not found or API error: ${data['status']}',
            statusCode: response.statusCode,
          );
        }
      } else {
        throw ServerException(response.body, statusCode: response.statusCode);
      }
    } on http.ClientException catch (e) {
      throw NetworkException(
        'Network error fetching place details: ${e.message}',
      );
    } on FormatException catch (e) {
      throw DataParsingException(
        'Failed to parse place details response: ${e.message}',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  @override
  Future<GeocodedAddressModel> getPlaceNameFromLatLng(LatLng latLng) async {
    _checkApiKey();
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=$googleMapsApiKey';
    debugPrint(
      'Reverse geocoding for ${latLng.latitude},${latLng.longitude}: $url',
    );

    try {
      final response = await client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        debugPrint('Data status: $data["status"]');
        // Check the status first
        if (data['status'] == 'OK') {
          if (data['results'].isNotEmpty) {
            final results = data['results'] as List;
            String formattedAddress = 'Unknown location';

            // Logic to find the best formatted address
            for (final result in results) {
              final address = result['formatted_address']
                  .toString()
                  .toLowerCase();
              if (!address.contains('unnamed road') && !address.contains('+')) {
                formattedAddress = result['formatted_address'];
                break;
              }
            }
            if (formattedAddress == 'Unknown location' && results.isNotEmpty) {
              formattedAddress = results.first['formatted_address'];
            }
            debugPrint('Reverse geocoded address: $formattedAddress');
            return GeocodedAddressModel.fromJson({
              'formatted_address': formattedAddress,
            }, latLng);
          } else {
            // This case should ideally not be hit if status is 'OK'
            // but added for robustness if 'OK' comes with empty results (unlikely for Google)
            debugPrint(
              'Google Geocoding API returned OK status but empty results.',
            );
            return GeocodedAddressModel.fromJson({
              'formatted_address': 'No address found for these coordinates.',
            }, latLng);
          }
        } else if (data['status'] == 'ZERO_RESULTS') {
          debugPrint(
            'Google Geocoding API returned ZERO_RESULTS for ${latLng.latitude},${latLng.longitude}',
          );
          // Return a default model or a specific message to the user
          return GeocodedAddressModel.fromJson({
            'formatted_address': 'No street address found for this location.',
          }, latLng);
        } else {
          // Handle other error statuses (e.g., REQUEST_DENIED, OVER_QUERY_LIMIT, etc.)
          throw ServerException(
            'Geocoding failed with status: ${data['status']}',
            statusCode: response.statusCode,
          );
        }
      } else {
        // Handle non-200 HTTP status codes (e.g., 400, 500)
        throw ServerException(
          'HTTP Error: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw NetworkException('Network error during geocoding: ${e.message}');
    } on FormatException catch (e) {
      throw DataParsingException(
        'Failed to parse geocoding response: ${e.message}',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
