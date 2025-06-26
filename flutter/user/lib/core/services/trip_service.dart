import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class TripService {
  static Future<List<Map<String, dynamic>>> fetchUserTrips(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/user/trips'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['trips']);
    } else {
      throw Exception('Failed to load trips');
    }
  }
}
