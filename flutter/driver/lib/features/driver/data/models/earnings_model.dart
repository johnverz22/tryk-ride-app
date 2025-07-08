class EarningsSummary {
  final double totalEarnings;
  final int totalTrips;
  final double averageFare;

  EarningsSummary({
    required this.totalEarnings,
    required this.totalTrips,
    required this.averageFare,
  });

  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    return EarningsSummary(
      totalEarnings: (json['total_earnings'] ?? 0).toDouble(),
      totalTrips: json['total_trips'] ?? 0,
      averageFare: (json['average_fare'] ?? 0).toDouble(),
    );
  }
}
