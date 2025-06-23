class TripEntity {
  final String id;
  final DateTime datetime;
  final String pickup;
  final String dropoff;
  final double price;
  final String payment;
  final String rider;
  final double? rating;
  final String status;

  const TripEntity({
    required this.id,
    required this.datetime,
    required this.pickup,
    required this.dropoff,
    required this.price,
    required this.payment,
    required this.rider,
    required this.status,
    this.rating,
  });
}
