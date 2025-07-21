import 'package:auth/features/auth/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({required super.token, required super.email, super.name, super.id});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      token: json['token'] ?? '',
      email: json['email'] ?? '',
      name: json['name'],
      id: json['id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'token': token, 'email': email, 'name': name, 'id': id};
  }
}
