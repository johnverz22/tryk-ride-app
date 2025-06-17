import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../../../../../core/params/params.dart';
import '../entities/user_entity.dart';
import '../repositories/user_repository.dart';

class GetUser {
  final UserRepository userRepository;

  GetUser({required this.userRepository});

  Future<Either<Failure, UserEntity>> call({
    required UserParams userParams,
  }) async {
    return await userRepository.getUser(userParams: userParams);
  }
}
