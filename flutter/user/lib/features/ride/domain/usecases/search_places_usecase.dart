import 'package:dartz/dartz.dart';
import 'package:user/features/core/errors/failures.dart';
import '../entities/place_entity.dart';
import '../repositories/place_repository.dart';

class SearchPlacesUseCase {
  final PlaceRepository repository;
  SearchPlacesUseCase(this.repository);

  Future<Either<Failure, List<PlaceSuggestionEntity>>> call(
    String query,
  ) async {
    return await repository.searchPlaces(query);
  }
}
