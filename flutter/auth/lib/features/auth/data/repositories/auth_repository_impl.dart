import 'package:auth/core/errors/exceptions.dart';
import 'package:auth/core/errors/failure.dart';
import 'package:dartz/dartz.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/auth_local_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, UserEntity>> login(
    String email,
    String password,
  ) async {
    try {
      final userModel = await remoteDataSource.login(email, password);
      await localDataSource.storeToken(userModel.token);
      await localDataSource.storeUser(userModel);
      return Right(userModel);
    } on InvalidCredentialsException {
      return const Left(InvalidCredentialsFailure());
    } on ValidationException {
      return const Left(ValidationFailure());
    } on ServerException {
      return const Left(ServerFailure());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on UnknownException catch (e) {
      return Left(UnknownFailure(e.message));
    } catch (e) {
      // Handle local storage errors or other unexpected errors
      return Left(UnknownFailure('Login failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register(
    String email,
    String password,
    String name,
  ) async {
    try {
      final userModel = await remoteDataSource.register(email, password, name);
      await localDataSource.storeToken(userModel.token);
      await localDataSource.storeUser(userModel);
      return Right(userModel);
    } on InvalidCredentialsException {
      return const Left(InvalidCredentialsFailure());
    } on ValidationException {
      return const Left(ValidationFailure());
    } on ServerException {
      return const Left(ServerFailure());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on UnknownException catch (e) {
      return Left(UnknownFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Registration failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      final token = await localDataSource.getToken();
      if (token != null) {
        try {
          await remoteDataSource.logout(token);
        } catch (e) {
          // Continue with local logout even if remote logout fails
          // This is expected behavior as mentioned in your original code
        }
      }
      await localDataSource.clearAll();
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure('Logout failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final token = await localDataSource.getToken();
      if (token == null) return const Right(null);

      // Try to get user from local storage first
      final localUser = await localDataSource.getUser();
      if (localUser != null) {
        return Right(localUser);
      }

      // If not in local storage, fetch from remote
      final userModel = await remoteDataSource.getCurrentUser(token);
      await localDataSource.storeUser(userModel);
      return Right(userModel);
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException {
      return const Left(ServerFailure());
    } on UnknownException catch (e) {
      return Left(UnknownFailure(e.message));
    } catch (e) {
      // If remote call fails, clear local storage and return null
      await localDataSource.clearAll();
      return const Right(null);
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      final token = await localDataSource.getToken();
      return token != null;
    } catch (e) {
      // If we can't access local storage, assume not logged in
      return false;
    }
  }
}
