import 'package:data_connection_checker_tv/data_connection_checker.dart';

import 'package:dio/dio.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/connection/network_info.dart';
import '../../../../../core/errors/failure.dart';
import '../../../../../core/params/params.dart';
import '../../business/entities/user_entity.dart';
import '../../business/usecases/get_user.dart';
import '../../data/datasources/user_local_data_source.dart';
import '../../data/datasources/user_remote_data_source.dart';
import '../../data/repositories/user_repository_impl.dart';

class UserProvider extends ChangeNotifier {
  UserEntity? user;
  Failure? failure;

  UserProvider({
    this.user,
    this.failure,
  });

  void eitherFailureOrUser() async {
    UserRepositoryImpl repository = UserRepositoryImpl(
      remoteDataSource: UserRemoteDataSourceImpl(
        dio: Dio(),
      ),
      localDataSource: UserLocalDataSourceImpl(
        sharedPreferences: await SharedPreferences.getInstance(),
      ),
      networkInfo: NetworkInfoImpl(
        DataConnectionChecker(),
      ),
    );

    final failureOrUser = await GetUser(userRepository: repository).call(
      userParams: UserParams(),
    );

    failureOrUser.fold(
      (Failure newFailure) {
        user = null;
        failure = newFailure;
        notifyListeners();
      },
      (UserEntity newUser) {
        user = newUser;
        failure = null;
        notifyListeners();
      },
    );
  }
}
