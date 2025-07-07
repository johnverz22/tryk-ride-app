import 'dart:convert';
import 'package:driver/presentation/providers/driver_provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/driver_model.dart';
import '../config/api_config.dart';

final storage = FlutterSecureStorage();
final baseUrl = ApiConfig.baseUrl;
class AuthService {
  final client = http.Client();

  // Register driver
  Future<bool> register(String name, String email, String password, BuildContext context, WidgetRef ref) async {
    try {
      final res = await client.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role_id': 3, // Or 3 for drivers
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final token = data['token']; // Sanctum key
        final driver = DriverModel.fromJson(json: data['user']);

        await storage.write(key: 'token', value: token);
        await storage.write(key: 'user', value: jsonEncode(data['user']));

        ref.read(driverProvider.notifier).setDriver(driver, token);
        return true;
      } else {
        debugPrint('[AuthService] Register failed: ${res.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[AuthService] Network error (register): $e');
      return false;
    }
  }

  // Login driver
  Future<bool> login(String email, String password, BuildContext context, WidgetRef ref) async {
    try {
      final res = await client.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final token = data['token']; // Sanctum key
        final driver = DriverModel.fromJson(json: data['user']);

        await storage.write(key: 'token', value: token);
        await storage.write(key: 'user', value: jsonEncode(data['user']));

        ref.read(driverProvider.notifier).setDriver(driver, token);
        return true;
      } else {
        print('[AuthService] Login failed: ${res.body}');
        return false;
      }
    } catch (e) {
      print('[AuthService] Network error (login): $e');
      return false;
    }
  }

  // Logout driver
  Future<void> logout(WidgetRef ref) async {
    try {
      final token = await getToken();
      if (token != null) {
        await client.post(
          Uri.parse('$baseUrl/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
      }
    } catch (e) {
      debugPrint('[AuthService] Network error (logout): $e');
    }

    await storage.delete(key: 'token');
    await storage.delete(key: 'user');
    ref.read(driverProvider.notifier).logout();
    debugPrint('[AuthService] Logged out');
  }

  // Get access token
  Future<String?> getToken() async {
    return await storage.read(key: 'token');
  }

  // Get stored driver
  Future<Map<String, dynamic>?> getDriver() async {
    final driverJson = await storage.read(key: 'user');
    if (driverJson != null) {
      return jsonDecode(driverJson);
    }
    return null;
  }

  // Check if logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}