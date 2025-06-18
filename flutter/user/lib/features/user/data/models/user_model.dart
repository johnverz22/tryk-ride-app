import '../../../../../core/constants/constants.dart';
import '../../business/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required String id,
    required String fullName,
    required String email,
    required String phoneNumber,
    String? profilePhotoUrl,
    required String role,
    required bool isVerified,
    required double walletBalance,
    String? defaultPaymentMethod,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? lastLoginAt,
  }) : super(
          id: id,
          fullName: fullName,
          email: email,
          phoneNumber: phoneNumber,
          profilePhotoUrl: profilePhotoUrl,
          role: role,
          isVerified: isVerified,
          walletBalance: walletBalance,
          defaultPaymentMethod: defaultPaymentMethod,
          createdAt: createdAt,
          updatedAt: updatedAt,
          lastLoginAt: lastLoginAt,
        );

      factory UserModel.fromJson({required Map<String, dynamic> json}) {
        return UserModel(
          id: json[kId]?.toString() ?? '',  // fallback to empty string if null
          fullName: json[kFullName] ?? '',
          email: json[kEmail] ?? '',
          phoneNumber: json[kPhoneNumber] ?? '',
          profilePhotoUrl: json[kProfilePhotoUrl] as String?,  // already nullable
          role: json[kRole] ?? '',
          isVerified: json[kIsVerified] ?? false,
          walletBalance: (json[kWalletBalance] as num?)?.toDouble() ?? 0.0,
          defaultPaymentMethod: json[kDefaultPaymentMethod] as String?,  // already nullable
          createdAt: json[kCreatedAt] != null
              ? DateTime.parse(json[kCreatedAt])
              : DateTime.now(),
          updatedAt: json[kUpdatedAt] != null
              ? DateTime.parse(json[kUpdatedAt])
              : DateTime.now(),
          lastLoginAt: json[kLastLoginAt] != null
              ? DateTime.parse(json[kLastLoginAt])
              : null,
        );
      }

  Map<String, dynamic> toJson() {
    return {
      kId: id,
      kFullName: fullName,
      kEmail: email,
      kPhoneNumber: phoneNumber,
      kProfilePhotoUrl: profilePhotoUrl,
      kRole: role,
      kIsVerified: isVerified,
      kWalletBalance: walletBalance,
      kDefaultPaymentMethod: defaultPaymentMethod,
      kCreatedAt: createdAt.toIso8601String(),
      kUpdatedAt: updatedAt.toIso8601String(),
      if (lastLoginAt != null) kLastLoginAt: lastLoginAt!.toIso8601String(),
    };
  }
}
