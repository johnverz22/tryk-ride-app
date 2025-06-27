import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../data/models/user_model.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  String? _token;
  String? baseUrl = dotenv.env['BASE_URL'];

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  UserProvider() {
    loadUserData();
  }

  UserModel? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _user != null && _token != null;

  Future<void> setUser(UserModel user, String token) async {
    _user = user;
    _token = token;
    await _storage.write(key: 'token', value: token);
    await _storage.write(key: 'user', value: jsonEncode(user.toJson()));
    notifyListeners();
  }

  Future<void> setToken(String token) async {
    _token = token;
    await _storage.write(key: 'token', value: token);
    notifyListeners();
  }

  Future<void> loadUserData() async {
    final token = await _storage.read(key: 'token');
    final userJson = await _storage.read(key: 'user');

    if (token != null) _token = token;

    if (userJson != null) {
      try {
        final userMap = jsonDecode(userJson);
        _user = UserModel.fromJson(json: userMap);
      } catch (e) {
        debugPrint('[UserProvider] Error decoding user: $e');
      }
    }

    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'user');
    notifyListeners();
  }

  Future<bool> refreshToken() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['token'];

        if (newToken != null) {
          await setToken(newToken);
          return true;
        }
      }
    } catch (e) {
      debugPrint('Token refresh failed: $e');
    }

    return false;
  }

  Future<http.Response> authenticatedRequest(
    String url,
    String method, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    headers ??= {};
    final token = await _storage.read(key: 'token');
    if (token != null) headers['Authorization'] = 'Bearer $token';

    http.Response response;
    final uri = Uri.parse(url);

    try {
      if (method == 'PUT') {
        response = await http.put(uri, headers: headers, body: body);
      } else {
        throw UnimplementedError('Method not supported');
      }

      // If token expired, try refresh
      if (response.statusCode == 401) {
        final refreshed = await refreshToken();

        if (refreshed) {
          final newToken = await _storage.read(key: 'token');
          if (newToken != null) headers['Authorization'] = 'Bearer $newToken';
          response = await http.put(uri, headers: headers, body: body); // retry
        }
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUser(UserModel updatedUser) async {
    if (_token == null) return;

    final response = await authenticatedRequest(
      '$baseUrl/user/update',
      'PUT',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updatedUser.toJson()),
    );

    if (response.statusCode == 200) {
      _user = updatedUser;
      await _storage.write(
        key: 'user',
        value: jsonEncode(updatedUser.toJson()),
      );
      notifyListeners();
    } else {
      debugPrint('Failed to update user: ${response.body}');
    }
  }
}
