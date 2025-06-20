import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../../../../../core/params/params.dart';
import '../entities/driver_entity.dart';
import '../repositories/driver_repository.dart';

class GetDriver {
  final DriverRepository driverRepository;

  GetDriver({required this.driverRepository});

  Future<Either<Failure, DriverEntity>> call({
    required DriverParams driverParams,
  }) async {
    return await driverRepository.getDriver(driverParams: driverParams);
  }
}
