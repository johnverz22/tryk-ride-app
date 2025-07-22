import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/params/params.dart';
import '../entities/driver_entity.dart';

abstract class DriverRepository {
  Future<Either<Failure, DriverEntity>> getDriver({
    required DriverParams driverParams,
  });
}
