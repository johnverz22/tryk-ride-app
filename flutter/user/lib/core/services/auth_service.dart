import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/user/data/models/user_model.dart';

final baseUrl = dotenv.env['BASE_URL'];

// Riverpod Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Response class
class AuthResponse {
  final bool success;
  final String? token;
  final UserModel? user;

  const AuthResponse({required this.success, this.token, this.user});
}

// Background parser (must be top-level for compute)
UserModel parseUser(Map<String, dynamic> json) {
  return UserModel.fromJson(json: json);
}

class AuthService {
  final http.Client client;
  final FlutterSecureStorage storage;

  AuthService({http.Client? client, FlutterSecureStorage? storage})
    : client = client ?? http.Client(),
      storage = storage ?? const FlutterSecureStorage();

  /// Register new user
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
          'role_id': 2,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final token = data['token'] as String;
        final user = await compute<Map<String, dynamic>, UserModel>(
          parseUser,
          Map<String, dynamic>.from(data['user']),
        );

        await saveCredentials(token, data['user']);
        return AuthResponse(success: true, token: token, user: user);
      }

      print('[AuthService] Register failed: ${res.body}');
      return const AuthResponse(success: false);
    } catch (e, stack) {
      print('[AuthService] Exception during register: $e\n$stack');
      return const AuthResponse(success: false);
    }
  }

  /// Login existing user
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
        final user = await compute<Map<String, dynamic>, UserModel>(
          parseUser,
          Map<String, dynamic>.from(data['user']),
        );

        await saveCredentials(token, data['user']);
        return AuthResponse(success: true, token: token, user: user);
      }

      print('[AuthService] Login failed: ${res.body}');
      return const AuthResponse(success: false);
    } catch (e, stack) {
      print('[AuthService] Exception during login: $e\n$stack');
      return const AuthResponse(success: false);
    }
  }

  /// Logout the current user
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
      await storage.delete(key: 'user');
      print('[AuthService] Logged out');
    }
  }

  /// Save token and user in secure storage
  Future<void> saveCredentials(String token, Map<String, dynamic> user) async {
    await storage.write(key: 'token', value: token);
    await storage.write(key: 'user', value: jsonEncode(user));
  }

  Future<String?> getToken() async => storage.read(key: 'token');

  Future<Map<String, dynamic>?> getUser() async {
    final userJson = await storage.read(key: 'user');
    return userJson != null ? jsonDecode(userJson) : null;
  }

  Future<bool> isLoggedIn() async => (await getToken()) != null;
}
