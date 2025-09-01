import 'package:dartz/dartz.dart';
import '../../business/entities/user_entity.dart';
import '../../business/repositories/user_repository.dart';
import '../../business/usecases/get_user_usecase.dart';
import '../datasources/user_local_datasource.dart';
import '../datasources/user_remote_datasource.dart';
import '../models/user_model.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;
  final UserLocalDataSource localDataSource;

  UserRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, UserData>> login(String email, String password) async {
    try {
      final result = await remoteDataSource.login(email, password);
      
      // Store user data locally
      await localDataSource.storeUser(result.user);
      await localDataSource.storeToken(result.token);
      
      return Right(UserData(
        user: result.user,
        token: result.token,
      ));
    } on ServerException {
      return Left(ServerFailure());
    } on NetworkException {
      return Left(NetworkFailure());
    } on AuthException {
      return Left(AuthFailure());
    }
  }

  @override
  Future<Either<Failure, UserData>> getStoredUser() async {
    try {
      final user = await localDataSource.getStoredUser();
      final token = await localDataSource.getStoredToken();
      
      if (user != null && token != null) {
        return Right(UserData(user: user, token: token));
      } else {
        return Left(CacheFailure());
      }
    } on CacheException {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateUser(UserEntity user) async {
    try {
      final userModel = UserModel.fromEntity(user);
      final updatedUser = await remoteDataSource.updateUser(userModel);
      
      // Update local storage
      await localDataSource.storeUser(updatedUser);
      
      return Right(updatedUser);
    } on ServerException {
      return Left(ServerFailure());
    } on NetworkException {
      return Left(NetworkFailure());
    } on AuthException {
      return Left(AuthFailure());
    }
  }

  @override
  Future<void> logout() async {
    await localDataSource.clearUserData();
  }

  @override
  Future<Either<Failure, String>> refreshToken() async {
    try {
      final newToken = await remoteDataSource.refreshToken();
      await localDataSource.storeToken(newToken);
      return Right(newToken);
    } on ServerException {
      return Left(ServerFailure());
    } on NetworkException {
      return Left(NetworkFailure());
    } on AuthException {
      return Left(AuthFailure());
    }
  }
}