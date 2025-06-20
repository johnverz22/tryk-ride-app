/// Used for functions with no parameters.
class NoParams {}

/// Placeholder for future template-related parameters.
class TemplateParams {}

/// Parameters required to fetch a specific user.
class UserParams {
  final String id;
  const UserParams({required this.id});
}

/// Parameters required to fetch a specific driver.
class DriverParams {
  final String id;
  const DriverParams({required this.id});
}
