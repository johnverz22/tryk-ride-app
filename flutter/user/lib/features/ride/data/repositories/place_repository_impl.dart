// user/features/ride/data/repositories/place_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:user/features/core/errors/exceptions.dart';
import 'package:user/features/core/errors/failures.dart';

import '../../domain/entities/place_entity.dart';
import '../../domain/repositories/place_repository.dart';
import '../datasources/place_remote_datasource.dart';

class PlaceRepositoryImpl implements PlaceRepository {
  final PlaceRemoteDataSource remoteDataSource;

  PlaceRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<PlaceSuggestionEntity>>> searchPlaces(
    String query,
  ) async {
    try {
      final result = await remoteDataSource.searchPlaces(query);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NoInternetFailure());
    } on DataParsingException catch (e) {
      return Left(DataParsingFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PlaceDetailsEntity>> getPlaceDetails(
    String placeId,
  ) async {
    try {
      final result = await remoteDataSource.getPlaceDetails(placeId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NoInternetFailure());
    } on DataParsingException catch (e) {
      return Left(DataParsingFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, GeocodedAddressEntity>> getPlaceNameFromLatLng(
    LatLng latLng,
  ) async {
    try {
      final result = await remoteDataSource.getPlaceNameFromLatLng(latLng);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NoInternetFailure());
    } on DataParsingException catch (e) {
      return Left(DataParsingFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
