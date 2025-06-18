import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/models/user_model.dart';

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
}
