/// Represents the earnings of a driver for a specific trip.
class EarningEntity {
  /// A unique identifier for the earning entity.
  final String tripId;

  /// The unique identifier for the driver who completed the trip.
  final String driverId;

  /// The start time of the trip.
  final DateTime tripStartTime;

  /// The end time of the trip.
  final DateTime tripEndTime;

  /// The total duration of the trip in minutes.
  final int tripDuration;

  /// The base fare charged for the trip (before additional charges).
  final double baseFare;

  /// The fare based on the distance traveled during the trip.
  final double distanceFare;

  /// The fare based on the time spent during the trip.
  final double timeFare;

  /// Additional fare applied due to surge pricing (if applicable).
  final double surgePricing;

  /// Any bonuses paid to the driver (e.g., trip completion bonuses).
  final double bonuses;

  /// The tips given by the rider.
  final double tips;

  /// The platform's service fee or commission deducted from the fare.
  final double platformFee;

  /// Any additional deductions (e.g., tax or other fees).
  final double deductions;

  /// The total earnings for the driver for this trip, after all charges and bonuses.
  final double totalEarnings;

  /// The current status of the earnings (e.g., "Paid", "Pending").
  final String status;

  /// The method by which the driver will receive the payout (e.g., "Bank Transfer").
  final String paymentMethod;

  /// The date and time when the driver received the payment.
  final DateTime payoutDate;

  /// The rating given by the rider for the driver's performance.
  final int tripRating;

  /// Additional comments or feedback from the rider (optional).
  final String? comments;

  /// Constructor to initialize all the fields of the EarningEntity.
  const EarningEntity({
    required this.tripId,
    required this.driverId,
    required this.tripStartTime,
    required this.tripEndTime,
    required this.tripDuration,
    required this.baseFare,
    required this.distanceFare,
    required this.timeFare,
    required this.surgePricing,
    required this.bonuses,
    required this.tips,
    required this.platformFee,
    required this.deductions,
    required this.totalEarnings,
    required this.status,
    required this.paymentMethod,
    required this.payoutDate,
    required this.tripRating,
    this.comments,
  });
}
