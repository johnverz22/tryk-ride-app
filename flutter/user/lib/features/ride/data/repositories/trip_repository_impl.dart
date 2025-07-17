import 'package:dartz/dartz.dart';
import 'package:user/features/core/errors/exceptions.dart';
import 'package:user/features/core/errors/failures.dart';

import '../../domain/entities/trip_entity.dart';
import '../../domain/repositories/trip_repository.dart';
import '../datasources/trip_remote_datasource.dart';

class TripRepositoryImpl implements TripRepository {
  final TripRemoteDataSource remoteDataSource;

  TripRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<TripEntity>>> getUserTrips(
    String token, {
    int page = 1,
  }) async {
    try {
      final result = await remoteDataSource.fetchUserTrips(token, page: page);
      return Right(result);
    } on ServerException catch (e) {
      // Correctly pass message and statusCode to ServerFailure
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException {
      // Map NetworkException to NoInternetFailure or a more general NetworkFailure if needed
      // Given your NetworkException message, NoInternetFailure seems appropriate.
      return const Left(NoInternetFailure());
    } on DataParsingException catch (e) {
      // Correctly map DataParsingException to DataParsingFailure
      return Left(DataParsingFailure(message: e.message));
    } on UnauthorizedException catch (e) {
      // Handle UnauthorizedException
      return Left(UnauthorizedFailure(e.message));
    } catch (e) {
      // Catch any other unexpected exceptions and map to UnexpectedFailure
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
