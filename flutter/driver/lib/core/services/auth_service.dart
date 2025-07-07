import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/driver/data/models/driver_model.dart';

final baseUrl = dotenv.env['BASE_URL'];

// Riverpod Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Response class
class AuthResponse {
  final bool success;
  final String? token;
  final DriverModel? driver;

  const AuthResponse({required this.success, this.token, this.driver});
}

// Background parser (must be top-level for compute)
DriverModel parsedriver(Map<String, dynamic> json) {
  return DriverModel.fromJson(json: json);
}

class AuthService {
  final http.Client client;
  final FlutterSecureStorage storage;

  AuthService({http.Client? client, FlutterSecureStorage? storage})
    : client = client ?? http.Client(),
      storage = storage ?? const FlutterSecureStorage();

  /// Register new driver
  Future<AuthResponse> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final res = await client.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role_id': 3,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final token = data['token'] as String;
        final driver = await compute<Map<String, dynamic>, DriverModel>(
          parsedriver,
          Map<String, dynamic>.from(data['driver']),
        );

        await saveCredentials(token, data['driver']);
        return AuthResponse(success: true, token: token, driver: driver);
      }

      print('[AuthService] Register failed: ${res.body}');
      return const AuthResponse(success: false);
    } catch (e, stack) {
      print('[AuthService] Exception during register: $e\n$stack');
      return const AuthResponse(success: false);
    }
  }

  /// Login existing driver
  Future<AuthResponse> login(String email, String password) async {
    try {
      final res = await client.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final token = data['token'] as String;
        final driver = await compute<Map<String, dynamic>, DriverModel>(
          parsedriver,
          Map<String, dynamic>.from(data['user']),
        );

        await saveCredentials(token, data['user']);
        return AuthResponse(success: true, token: token, driver: driver);
      }

      print('[AuthService] Login failed: ${res.body}');
      return const AuthResponse(success: false);
    } catch (e, stack) {
      print('[AuthService] Exception during login: $e\n$stack');
      return const AuthResponse(success: false);
    }
  }

  /// Logout the current driver
  Future<void> logout({String? token}) async {
    try {
      final authToken = token ?? await getToken();
      if (authToken != null) {
        await client.post(
          Uri.parse('$baseUrl/logout'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        );
      }
    } catch (e) {
      print('[AuthService] Network error (logout): $e');
    } finally {
      await storage.delete(key: 'token');
      await storage.delete(key: 'driver');
      print('[AuthService] Logged out');
    }
  }

  /// Save token and driver in secure storage
  Future<void> saveCredentials(
    String token,
    Map<String, dynamic> driver,
  ) async {
    await storage.write(key: 'token', value: token);
    await storage.write(key: 'driver', value: jsonEncode(driver));
  }

  Future<String?> getToken() async => storage.read(key: 'token');

  Future<Map<String, dynamic>?> getdriver() async {
    final driverJson = await storage.read(key: 'driver');
    return driverJson != null ? jsonDecode(driverJson) : null;
  }

  Future<bool> isLoggedIn() async => (await getToken()) != null;
}
