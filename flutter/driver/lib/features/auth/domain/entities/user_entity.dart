class User {
  final String id;
  final String email;
  final String username;
  final bool isEmailVerified;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.username,
    required this.isEmailVerified,
    required this.createdAt,
  });
}
