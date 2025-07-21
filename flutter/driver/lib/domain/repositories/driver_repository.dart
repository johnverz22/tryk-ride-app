import '../../../core/params/params.dart';
import '../entities/driver_entity.dart';

abstract class DriverRepository {
  Future<DriverEntity> getDriver({required DriverParams driverParams});
}

//TODO: CHECK THIS
