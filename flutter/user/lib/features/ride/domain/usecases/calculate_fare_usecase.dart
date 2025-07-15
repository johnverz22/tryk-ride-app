// domain/usecases/calculate_fare_usecase.dart
class CalculateFareUseCase {
  static const double _baseFare = 5.0;
  static const double _perKmRate = 2.0;

  double call(double distanceKm) {
    return _baseFare + (_perKmRate * distanceKm);
  }

  double getEstimatedDuration(double distanceKm) {
    return distanceKm / 40 * 60; // Assuming 40 km/h average speed
  }
}
