import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../../../../core/errors/exceptions.dart';

abstract class UserLocalDataSource {
  Future<UserModel?> getStoredUser();
  Future<String?> getStoredToken();
  Future<void> storeUser(UserModel user);
  Future<void> storeToken(String token);
  Future<void> clearUserData();
}

class UserLocalDataSourceImpl implements UserLocalDataSource {
  final FlutterSecureStorage secureStorage;

  UserLocalDataSourceImpl({required this.secureStorage});

  @override
  Future<UserModel?> getStoredUser() async {
    try {
      final userJson = await secureStorage.read(key: 'user');
      if (userJson != null) {
        final userMap = jsonDecode(userJson);
        return UserModel.fromJson(json: userMap);
      }
      return null;
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<String?> getStoredToken() async {
    try {
      return await secureStorage.read(key: 'token');
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<void> storeUser(UserModel user) async {
    try {
      await secureStorage.write(
        key: 'user',
        value: jsonEncode(user.toJson()),
      );
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<void> storeToken(String token) async {
    try {
      await secureStorage.write(key: 'token', value: token);
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<void> clearUserData() async {
    try {
      await secureStorage.delete(key: 'user');
      await secureStorage.delete(key: 'token');
    } catch (e) {
      throw CacheException();
    }
  }
}