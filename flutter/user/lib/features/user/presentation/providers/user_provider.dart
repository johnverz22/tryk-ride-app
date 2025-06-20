import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/models/user_model.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/api_config.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  String? _token;

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

  Future<void> updateUser(UserModel updatedUser) async {
    if (_token == null) return;

    final baseUrl = ApiConfig.baseUrl;
    final response = await http.put(
      Uri.parse('$baseUrl/user/update'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode(updatedUser.toJson()),
    );

    if (response.statusCode == 200) {
      _user = updatedUser;
      await _storage.write(key: 'user', value: jsonEncode(updatedUser.toJson()));
      notifyListeners();
    } else {
      debugPrint('Failed to update user: ${response.body}');
    }
  }
}
