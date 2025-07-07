import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../data/models/user_model.dart';

// Top-level function for compute()
UserModel parseUserJson(String jsonString) {
  final userMap = jsonDecode(jsonString);
  return UserModel.fromJson(json: userMap);
}

class UserState {
  final UserModel? user;
  final String? token;

  const UserState({this.user, this.token});

  bool get isAuthenticated => user != null && token != null;

  UserState copyWith({UserModel? user, String? token}) {
    return UserState(user: user ?? this.user, token: token ?? this.token);
  }
}

class UserNotifier extends AsyncNotifier<UserState?> {
  final _storage = const FlutterSecureStorage();
  String? get baseUrl => dotenv.env['BASE_URL'];

  @override
  Future<UserState> build() async {
    final token = await _storage.read(key: 'token');
    final userJson = await _storage.read(key: 'user');
    UserModel? user;

    if (userJson != null) {
      try {
        user = await compute(parseUserJson, userJson);
      } catch (e) {
        print('[UserNotifier] Error decoding user: $e');
      }
    }

    return UserState(user: user, token: token);
  }

  Future<void> setUser(UserModel? user, String? token) async {
    if (user == null || token == null) {
      await _storage.delete(key: 'token');
      await _storage.delete(key: 'user');
      state = AsyncData(null);
      return;
    }

    await _storage.write(key: 'token', value: token);
    await _storage.write(key: 'user', value: jsonEncode(user.toJson()));
    state = AsyncData(UserState(user: user, token: token));
  }

  Future<void> setToken(String token) async {
    await _storage.write(key: 'token', value: token);
    final current = state.valueOrNull;
    state = AsyncData(
      current?.copyWith(token: token) ?? UserState(token: token),
    );
  }

  Future<void> logout() async {
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'user');
    state = const AsyncData(UserState());
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
      print('Token refresh failed: $e');
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
    final token = state.value?.token ?? await _storage.read(key: 'token');
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final uri = Uri.parse(url);
    http.Response response;

    try {
      if (method == 'PUT') {
        response = await http.put(uri, headers: headers, body: body);
      } else {
        throw UnimplementedError('Method not supported');
      }

      if (response.statusCode == 401) {
        final refreshed = await refreshToken();
        if (refreshed) {
          final newToken =
              state.value?.token ?? await _storage.read(key: 'token');
          if (newToken != null) headers['Authorization'] = 'Bearer $newToken';
          response = await http.put(uri, headers: headers, body: body);
        }
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUser(UserModel updatedUser) async {
    final token = state.value?.token;
    if (token == null) return;

    final response = await authenticatedRequest(
      '$baseUrl/user/update',
      'PUT',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updatedUser.toJson()),
    );

    if (response.statusCode == 200) {
      await _storage.write(
        key: 'user',
        value: jsonEncode(updatedUser.toJson()),
      );
      state = AsyncData(
        state.value?.copyWith(user: updatedUser) ??
            UserState(user: updatedUser, token: token),
      );
    } else {
      print('Failed to update user: ${response.body}');
    }
  }
}

final userProvider = AsyncNotifierProvider<UserNotifier, UserState?>(
  () => UserNotifier(),
);
