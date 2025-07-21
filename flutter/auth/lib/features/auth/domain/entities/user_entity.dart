class UserEntity {
  final String token;
  final String email;
  final String? name;
  final int? id;

  UserEntity({required this.token, required this.email, this.name, this.id});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserEntity &&
        other.token == token &&
        other.email == email &&
        other.name == name &&
        other.id == id;
  }

  @override
  int get hashCode =>
      token.hashCode ^ email.hashCode ^ name.hashCode ^ id.hashCode;
}
