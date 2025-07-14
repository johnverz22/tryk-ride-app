class UserEntity {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profilePhotoUrl;
  final String role; // 'rider' or 'driver'
  final bool isVerified;
  final double walletBalance;
  final String? defaultPaymentMethod;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
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
