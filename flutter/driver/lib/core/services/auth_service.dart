import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/driver/data/models/driver_model.dart';
import '../../features/driver/presentation/providers/driver_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final storage = FlutterSecureStorage();
final baseUrl = dotenv.env['BASE_URL'];

class AuthService {
  final client = http.Client();

  // Register user
  Future<bool> register(
    String name,
    String email,
    String password,
    WidgetRef ref,
  ) async {
    try {
      final res = await client.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role_id': 2,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final token = data['token'];
        final user = DriverModel.fromJson(json: data['user']);

        await storage.write(key: 'token', value: token);
        await storage.write(key: 'user', value: jsonEncode(data['user']));

        ref.read(driverProvider.notifier).setDriver(user, token);
        return true;
      } else {
        print('[AuthService] Register failed: ${res.body}');
        return false;
      }
    } catch (e) {
      print('[AuthService] Network error (register): $e');
      return false;
    }
  }

  // Login user
  Future<bool> login(String email, String password, WidgetRef ref) async {
    try {
      final res = await client.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final token = data['token'];
        final user = DriverModel.fromJson(json: data['user']);

        await storage.write(key: 'token', value: token);
        await storage.write(key: 'user', value: jsonEncode(data['user']));

        ref.read(driverProvider.notifier).setDriver(user, token);
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

  // Logout user
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
      print('[AuthService] Network error (logout): $e');
    }

    await storage.delete(key: 'token');
    await storage.delete(key: 'user');
    ref.read(driverProvider.notifier).logout();
    print('[AuthService] Logged out');
  }

  // Get access token
  Future<String?> getToken() async {
    return await storage.read(key: 'token');
  }

  // Get stored user
  Future<Map<String, dynamic>?> getUser() async {
    final userJson = await storage.read(key: 'user');
    if (userJson != null) {
      return jsonDecode(userJson);
    }
    return null;
  }

  // Check if logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
