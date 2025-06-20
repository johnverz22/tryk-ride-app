import '../../../../../core/constants/constants.dart';
import '../../business/entities/user_entity.dart';

class UserModel extends UserEntity {
  final String? location;

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
    this.location,
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
      id: json[kId]?.toString() ?? '',
      fullName: json[kFullName] ?? '',
      email: json[kEmail]?.toString() ?? '',
      phoneNumber: json[kPhoneNumber]?.toString() ?? '',
      profilePhotoUrl: json[kProfilePhotoUrl] as String?,
      role: json[kRole]?.toString() ?? '',
      isVerified: json[kIsVerified] ?? false,
      walletBalance: (json[kWalletBalance] as num?)?.toDouble() ?? 0.0,
      defaultPaymentMethod: json[kDefaultPaymentMethod] as String?,
      createdAt: json[kCreatedAt] != null
          ? DateTime.parse(json[kCreatedAt])
          : DateTime.now(),
      updatedAt: json[kUpdatedAt] != null
          ? DateTime.parse(json[kUpdatedAt])
          : DateTime.now(),
      lastLoginAt: json[kLastLoginAt] != null
          ? DateTime.parse(json[kLastLoginAt])
          : null,
      location: json['location'] as String?,
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
      if (location != null) 'location': location,
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? profilePhotoUrl,
    String? role,
    bool? isVerified,
    double? walletBalance,
    String? defaultPaymentMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    String? location,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      walletBalance: walletBalance ?? this.walletBalance,
      defaultPaymentMethod: defaultPaymentMethod ?? this.defaultPaymentMethod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      location: location ?? this.location,
    );
  }
}
