import '../../domain/entities/trip_entity.dart';

abstract class TripRemoteDataSource {
  Future<List<TripEntity>> fetchUserTrips(String token, {int page = 1});
}
