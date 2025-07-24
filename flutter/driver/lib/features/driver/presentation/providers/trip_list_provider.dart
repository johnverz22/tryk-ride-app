import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// 1. Define the state using a typedef for simplicity. It's an AsyncValue holding the list of trips.
typedef DriverTripListState = AsyncValue<List<Map<String, dynamic>>>;

// 2. Create the StateNotifier to manage the state.
class DriverTripListNotifier extends StateNotifier<DriverTripListState> {
  DriverTripListNotifier() : super(const AsyncValue.loading());

  final _storage = const FlutterSecureStorage();
  String? get baseUrl => dotenv.env['BASE_URL'];

  Map<String, String> _authHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  // The fetching logic is moved here from the main DriverNotifier.
  Future<void> fetchTrips() async {
    // Set state to loading before the API call
    state = const AsyncValue.loading();

    try {
      // Securely get the token. This is a critical step.
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('Authentication token not found. Please log in again.');
      }

      final res = await http.get(
        Uri.parse('$baseUrl/api/driver/trips'),
        headers: _authHeaders(token),
      );

      if (res.statusCode == 200) {
        final decodedJson = jsonDecode(res.body);

        List<dynamic> rawTripsList;
        if (decodedJson is Map && decodedJson.containsKey('data')) {
          rawTripsList = decodedJson['data'] as List<dynamic>;
        } else if (decodedJson is List) {
          rawTripsList = decodedJson;
        } else {
          throw Exception('Unexpected JSON format received from server.');
        }

        final trips = List<Map<String, dynamic>>.from(rawTripsList);
        // On success, update the state with the data
        state = AsyncValue.data(trips);
      } else {
        throw Exception('Failed to load trips. Status code: ${res.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Fetch trips error: $e');
      // On failure, update the state with the error
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// 3. Define the final provider that the UI will interact with.
final driverTripListProvider =
    StateNotifierProvider<DriverTripListNotifier, DriverTripListState>((ref) {
      return DriverTripListNotifier();
    });
