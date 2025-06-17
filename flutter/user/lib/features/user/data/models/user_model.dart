import '../../../../../core/constants/constants.dart';
import '../../business/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
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
      id: json[kId] as String,
      fullName: json[kFullName] as String,
      email: json[kEmail] as String,
      phoneNumber: json[kPhoneNumber] as String,
      profilePhotoUrl: json[kProfilePhotoUrl] as String?,
      role: json[kRole] as String,
      isVerified: json[kIsVerified] as bool,
      walletBalance: (json[kWalletBalance] as num).toDouble(),
      defaultPaymentMethod: json[kDefaultPaymentMethod] as String?,
      createdAt: DateTime.parse(json[kCreatedAt] as String),
      updatedAt: DateTime.parse(json[kUpdatedAt] as String),
      lastLoginAt: json[kLastLoginAt] != null
          ? DateTime.parse(json[kLastLoginAt] as String)
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
