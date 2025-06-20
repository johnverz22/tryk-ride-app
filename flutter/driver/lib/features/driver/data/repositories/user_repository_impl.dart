import 'package:dartz/dartz.dart';

import '../../../../../core/connection/network_info.dart';
import '../../../../../core/errors/exceptions.dart';
import '../../../../../core/errors/failure.dart';
import '../../../../../core/params/params.dart';
import '../../business/repositories/driver_repository.dart';
import '../datasources/driver_local_data_source.dart';
import '../datasources/driver_remote_data_source.dart';
import '../models/driver_model.dart';

class DriverRepositoryImpl implements DriverRepository {
  final DriverRemoteDataSource remoteDataSource;
  final DriverLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  DriverRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, DriverModel>> getDriver({
    required DriverParams driverParams,
  }) async {
    if (await networkInfo.isConnected!) {
      try {
        final remoteDriver =
            await remoteDataSource.getDriver(driverParams: driverParams);

        localDataSource.cacheDriver(driverToCache: remoteDriver);

        return Right(remoteDriver);
      } on ServerException {
        return Left(ServerFailure(errorMessage: 'This is a server exception'));
      }
    } else {
      try {
        final localDriver = await localDataSource.getLastDriver();
        return Right(localDriver);
      } on CacheException {
        return Left(CacheFailure(errorMessage: 'This is a cache exception'));
      }
    }
  }
}
