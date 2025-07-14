class Trip {
  final String id;
  final DateTime datetime;
  final String pickup;
  final String dropoff;
  final double price;
  final String payment;
  final String driver;
  final double rating;
  final String status;

  Trip({
    required this.id,
    required this.datetime,
    required this.pickup,
    required this.dropoff,
    required this.price,
    required this.payment,
    required this.driver,
    required this.rating,
    required this.status,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'].toString(),
      datetime: DateTime.parse(json['completed_at'] ?? json['requested_at']),
      pickup: json['pickup_address'],
      dropoff: json['dropoff_address'],
      price: (json['fare_amount'] ?? 0).toDouble(),
      payment: json['payment_method'] ?? 'Unknown',
      driver: json['driver_name'] ?? 'Unknown',
      rating: (json['rider_rating'] ?? 0).toDouble(),
      status: json['status'],
    );
  }
}
