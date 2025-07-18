import 'package:dartz/dartz.dart';
import 'package:user/features/core/errors/failures.dart';
import '../entities/place_entity.dart';
import '../repositories/place_repository.dart';

class GetPlaceDetailsUseCase {
  final PlaceRepository repository;
  GetPlaceDetailsUseCase(this.repository);

  Future<Either<Failure, PlaceDetailsEntity>> call(String placeId) async {
    return await repository.getPlaceDetails(placeId);
  }
}
