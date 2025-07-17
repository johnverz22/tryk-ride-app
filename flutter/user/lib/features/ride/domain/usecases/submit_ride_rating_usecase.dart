import 'package:dartz/dartz.dart';
import 'package:user/features/core/errors/failures.dart';
import 'package:user/features/ride/domain/entities/rating.dart';
import 'package:user/features/ride/domain/repositories/rating_repository.dart';

class SubmitRideRatingUseCase {
  final RatingRepository repository;

  SubmitRideRatingUseCase(this.repository);

  Future<Either<Failure, void>> call(int rideId, Rating rating) async {
    return await repository.submitRideRating(rideId, rating);
  }
}
