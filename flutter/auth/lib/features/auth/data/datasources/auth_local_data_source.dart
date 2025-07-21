import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import 'dart:convert';

abstract class AuthLocalDataSource {
  Future<void> storeToken(String token);
  Future<String?> getToken();
  Future<void> storeUser(UserModel user);
  Future<UserModel?> getUser();
  Future<void> clearAll();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage storage;

  AuthLocalDataSourceImpl({required this.storage});

  @override
  Future<void> storeToken(String token) async {
    await storage.write(key: 'token', value: token);
  }

  @override
  Future<String?> getToken() async {
    return await storage.read(key: 'token');
  }

  @override
  Future<void> storeUser(UserModel user) async {
    await storage.write(key: 'user', value: jsonEncode(user.toJson()));
  }

  @override
  Future<UserModel?> getUser() async {
    final userJson = await storage.read(key: 'user');
    if (userJson != null) {
      return UserModel.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  @override
  Future<void> clearAll() async {
    await storage.deleteAll();
  }
}
