import '../../../../../core/constants/constants.dart';
import '../../business/entities/user_entity.dart';

class UserModel extends UserEntity {
  final String? location;

  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.phone,
    super.profilePhotoUrl,
    required super.role,
    required super.isVerified,
    required super.walletBalance,
    super.defaultPaymentMethod,
    required super.createdAt,
    required super.updatedAt,
    super.lastLoginAt,
    this.location,
  });

  factory UserModel.fromJson({required Map<String, dynamic> json}) {
    return UserModel(
      id: json[kId]?.toString() ?? '',
      name: json[kName]?.toString() ?? '',
      email: json[kEmail]?.toString() ?? '',
      phone: json[kPhone]?.toString() ?? '',
      profilePhotoUrl: json[kProfilePhotoUrl] as String?,
      role: json[kRole]?.toString() ?? '',
      isVerified: json[kIsVerified] is bool
          ? json[kIsVerified]
          : json[kIsVerified]?.toString().toLowerCase() == 'true',
      walletBalance: (json[kWalletBalance] as num?)?.toDouble() ?? 0.0,
      defaultPaymentMethod: json[kDefaultPaymentMethod] as String?,
      createdAt:
          DateTime.tryParse(json[kCreatedAt]?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json[kUpdatedAt]?.toString() ?? '') ??
          DateTime.now(),
      lastLoginAt: DateTime.tryParse(json[kLastLoginAt]?.toString() ?? ''),
      location: json['location']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      kId: id,
      kName: name,
      kEmail: email,
      kPhone: phone,
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
    String? name,
    String? email,
    String? phone,
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
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
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
