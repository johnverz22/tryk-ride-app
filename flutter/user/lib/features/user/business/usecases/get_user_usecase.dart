import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';
import '../repositories/user_repository.dart';
import '../../../../core/errors/failures.dart';

class UserData {
  final UserEntity user;
  final String token;

  UserData({required this.user, required this.token});
}

class GetUserUseCase {
  final UserRepository repository;

  GetUserUseCase(this.repository);

  Future<Either<Failure, UserData>> call() async {
    return await repository.getStoredUser();
  }
}