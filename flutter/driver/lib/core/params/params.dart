/// Used for functions with no parameters.
class NoParams {}

/// Placeholder for future template-related parameters.
class TemplateParams {}

/// Parameters required to fetch a specific user.
class AuthParams {
  final String email;
  final String password;
  const AuthParams({required this.email, required this.password});
}

/// Parameters required to fetch a specific driver.
class DriverParams {
  final String id;
  const DriverParams({required this.id});
}
