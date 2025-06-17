class UserEntity {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String? profilePhotoUrl;
  final String role; // 'rider' or 'driver'
  final bool isVerified;
  final double walletBalance;
  final String? defaultPaymentMethod;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;

  UserEntity({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.profilePhotoUrl,
    required this.role,
    required this.isVerified,
    required this.walletBalance,
    this.defaultPaymentMethod,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
  });
}
