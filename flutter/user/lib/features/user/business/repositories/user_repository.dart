import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';
import '../usecases/get_user_usecase.dart';
import '../../../../core/errors/failures.dart';

abstract class UserRepository {
  Future<Either<Failure, UserData>> login(String email, String password);
  Future<Either<Failure, UserData>> getStoredUser();
  Future<Either<Failure, UserEntity>> updateUser(UserEntity user);
  Future<void> logout();
  Future<Either<Failure, String>> refreshToken();
}