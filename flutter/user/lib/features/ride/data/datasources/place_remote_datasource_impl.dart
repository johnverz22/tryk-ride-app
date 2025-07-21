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

    final placesUrl =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${latLng.latitude},${latLng.longitude}&radius=50&key=$googleMapsApiKey';
    final geocodingUrl =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=$googleMapsApiKey';

    try {
      String city = '';
      String province = '';
      String country = '';

      final geoResponse = await client.get(Uri.parse(geocodingUrl));
      if (geoResponse.statusCode == 200) {
        final geoData = jsonDecode(geoResponse.body);
        if (geoData['status'] == 'OK') {
          final addressComponents =
              geoData['results'][0]['address_components'] as List;
          for (final comp in addressComponents) {
            final types = List<String>.from(comp['types'] ?? []);
            if (types.contains('locality')) {
              city = comp['long_name'];
            } else if (types.contains('administrative_area_level_2')) {
              province = comp['long_name'];
            } else if (types.contains('country')) {
              country = comp['long_name'];
            }
          }
        }
      }

      // Step 2: Try Places API for specific POI
      final placesResponse = await client.get(Uri.parse(placesUrl));

      if (placesResponse.statusCode == 200) {
        final placesData = jsonDecode(placesResponse.body);
        final placesResults = placesData['results'] as List?;

        if (placesData['status'] == 'OK' &&
            placesResults != null &&
            placesResults.isNotEmpty) {
          for (final place in placesResults) {
            final types = List<String>.from(place['types'] ?? []);
            if (types.contains('establishment') ||
                types.contains('point_of_interest')) {
              final name = place['name'];
              final formatted = _formatWithAdminLevels(
                name,
                city,
                province,
                country,
              );
              return GeocodedAddressModel.fromJson({
                'formatted_address': formatted,
              }, latLng);
            }
          }

          // Fallback to first place result
          final place = placesResults.first;
          final name = place['name'];
          final formatted = _formatWithAdminLevels(
            name,
            city,
            province,
            country,
          );
          return GeocodedAddressModel.fromJson({
            'formatted_address': formatted,
          }, latLng);
        }
      }

      // Step 3: Fallback to Geocoding API address only
      if (geoResponse.statusCode == 200) {
        final data = jsonDecode(geoResponse.body);
        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          String formattedAddress = 'Unknown location';

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

          return GeocodedAddressModel.fromJson({
            'formatted_address': formattedAddress,
          }, latLng);
        }
      }

      // Final fallback
      return GeocodedAddressModel.fromJson({
        'formatted_address': 'No address found for these coordinates.',
      }, latLng);
    } catch (e) {
      throw Exception('Error resolving place name: $e');
    }
  }

  /// Helper to combine name with city, province, country
  String _formatWithAdminLevels(
    String name,
    String city,
    String province,
    String country,
  ) {
    final buffer = StringBuffer(name);
    if (city.isNotEmpty) buffer.write(', $city');
    if (province.isNotEmpty) buffer.write(', $province');
    if (country.isNotEmpty) buffer.write(', $country');
    return buffer.toString();
  }
}
