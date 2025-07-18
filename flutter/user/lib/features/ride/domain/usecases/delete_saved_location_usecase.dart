import 'package:dartz/dartz.dart';
import 'package:user/features/core/errors/failures.dart';
import '../repositories/location_repository.dart';

class DeleteSavedLocationUseCase {
  final LocationRepository repository;
  DeleteSavedLocationUseCase(this.repository);

  Future<Either<Failure, Unit>> call(String token, int id) async {
    return await repository.deleteSavedLocation(token, id);
  }
}
