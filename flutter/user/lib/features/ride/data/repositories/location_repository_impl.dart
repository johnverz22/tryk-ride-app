import 'package:dartz/dartz.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:user/features/core/errors/exceptions.dart';
import 'package:user/features/core/errors/failures.dart';

import '../../domain/entities/location_entity.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/location_remote_datasource.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationRemoteDataSource remoteDataSource;
  // Optional: final LocationLocalDataSource localDataSource; // If you add local caching

  LocationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<LocationEntity>>> fetchSavedLocations(
    String token,
  ) async {
    try {
      final result = await remoteDataSource.fetchSavedLocations(token);
      // Optional: Save to local cache here
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NoInternetFailure());
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on DataParsingException catch (e) {
      return Left(DataParsingFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, LocationEntity>> addSavedLocation(
    String token,
    String name,
    LatLng latLng,
  ) async {
    try {
      final result = await remoteDataSource.addSavedLocation(
        token,
        name,
        latLng,
      );
      // Optional: Add to local cache here
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NoInternetFailure());
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on DataParsingException catch (e) {
      return Left(DataParsingFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, LocationEntity>> updateSavedLocation(
    String token,
    int id,
    String name,
    LatLng latLng,
  ) async {
    try {
      final result = await remoteDataSource.updateSavedLocation(
        token,
        id,
        name,
        latLng,
      );
      // Optional: Update in local cache here
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NoInternetFailure());
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on DataParsingException catch (e) {
      return Left(DataParsingFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteSavedLocation(
    String token,
    int id,
  ) async {
    try {
      await remoteDataSource.deleteSavedLocation(token, id);
      // Optional: Delete from local cache here
      return const Right(unit); // Use unit for void return
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NoInternetFailure());
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
