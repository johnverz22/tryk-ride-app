import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

abstract class UserLocalDataSource {
  Future<void> cacheUser({required UserModel? userToCache});
  Future<UserModel> getLastUser();
}

const cachedUser = 'CACHED_USER';

class UserLocalDataSourceImpl implements UserLocalDataSource {
  final SharedPreferences sharedPreferences;

  UserLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<UserModel> getLastUser() {
    final jsonString = sharedPreferences.getString(cachedUser);

    if (jsonString != null) {
      return Future.value(UserModel.fromJson(json: json.decode(jsonString)));
    } else {
      throw CacheException();
    }
  }

  @override
  Future<void> cacheUser({required UserModel? userToCache}) async {
    if (userToCache != null) {
      sharedPreferences.setString(
        cachedUser,
        json.encode(
          userToCache.toJson(),
        ),
      );
    } else {
      throw CacheException();
    }
  }
}
// This code defines a local data source for caching user data using SharedPreferences.
// It provides methods to cache a user and retrieve the last cached user.
