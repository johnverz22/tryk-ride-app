import 'package:dartz/dartz.dart';
import 'package:user/features/core/errors/failures.dart';
import 'package:user/features/ride/domain/entities/rating.dart';

abstract class RatingRepository {
  Future<Either<Failure, void>> submitRideRating(int rideId, Rating rating);
}
