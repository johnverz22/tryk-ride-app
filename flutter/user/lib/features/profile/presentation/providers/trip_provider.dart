import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Trip {
  final String id;
  final DateTime datetime;
  final String pickup_address;
  final String dropoff_address;
  final double price;
  final String payment;
  final String driver;
  final double rating;
  final String status;

  Trip({
    required this.id,
    required this.datetime,
    required this.pickup_address,
    required this.dropoff_address,
    required this.price,
    required this.payment,
    required this.driver,
    required this.rating,
    required this.status,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'].toString(),
      datetime: DateTime.parse(json['completed_at'] ?? json['requested_at']),
      pickup_address: json['pickup_address'] ?? '',
      dropoff_address: json['dropoff_address'] ?? '',
      price: (json['fare_amount'] ?? 0).toDouble(),
      payment: json['payment_method'] ?? 'Unknown',
      driver: json['driver'] != null
          ? json['driver']['name'] ?? 'Unknown'
          : 'Unknown',
      rating: json['rider_rating'] != null
          ? (json['rider_rating']).toDouble()
          : 0.0,
      status: json['status'] != null
          ? json['status']['name'] ?? 'Unknown'
          : 'Unknown',
    );
  }

  static Future<List<Trip>> fetchOngoingTrips(
    String? token,
    String baseUrl,
  ) async {
    final uri = Uri.parse('$baseUrl/api/rides/ongoing');
    try {
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // The decoding is now safely inside the try-catch block
        final List<dynamic> tripsJson = jsonDecode(response.body)['rides'];
        return tripsJson.map((json) => Trip.fromJson(json)).toList();
      } else {
        // Provide more context on failure
        throw Exception(
          'Failed to load trips. Status code: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } on FormatException catch (e) {
      // This is where your specific error will be caught!
      debugPrint('Error decoding JSON from $uri: $e');
      // You can log the first few characters of the body to see what you received
      // final responseForDebug = await http.get(uri);
      // debugPrint('Truncated response body: ${responseForDebug.body.substring(0, 500)}...');
      throw Exception(
        'Failed to parse server response. The data may be malformed or incomplete.',
      );
    } catch (e) {
      // Catch any other exceptions (network errors, etc.)
      debugPrint('An unexpected error occurred: $e');
      throw Exception('Could not connect to the server.');
    }
  }
}
