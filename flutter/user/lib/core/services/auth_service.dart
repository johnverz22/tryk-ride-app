import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();
const baseUrl = 'http://192.168.109.188:8000/api'; // Replace with your Laravel server IP

class AuthService {
  // Register user
  Future<bool> register(String name, String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await storage.write(key: 'token', value: data['token']);
        await storage.write(key: 'user', value: jsonEncode(data['user']));
        print('[AuthService] Register success');
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
  Future<bool> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await storage.write(key: 'token', value: data['token']);
        await storage.write(key: 'user', value: jsonEncode(data['user']));
        print('[AuthService] Login success');
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
  Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        await http.post(
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
    print('[AuthService] Logged out');
  }

  // Get stored token
  Future<String?> getToken() async {
    return await storage.read(key: 'token');
  }

  // Get stored user info (as a Map)
  Future<Map<String, dynamic>?> getUser() async {
    final userJson = await storage.read(key: 'user');
    if (userJson != null) {
      return jsonDecode(userJson);
    }
    return null;
  }

  // Check if user is authenticated
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
