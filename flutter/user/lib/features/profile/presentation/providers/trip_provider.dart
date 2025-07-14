import 'dart:convert';
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

  // Static method to fetch ongoing trips
  static Future<List<Trip>> fetchOngoingTrips(
    String? token,
    String baseUrl,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/rides/ongoing'),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> tripsJson = jsonDecode(response.body)['rides'];
      return tripsJson.map((json) => Trip.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load ongoing trips');
    }
  }
}
