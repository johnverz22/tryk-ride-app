abstract class AuthException implements Exception {
  final String message;
  final String code;

  const AuthException(this.message, this.code);

  @override
  String toString() => 'AuthException: $message (Code: $code)';
}

class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException()
    : super('Invalid email or password', 'INVALID_CREDENTIALS');
}

class ValidationException extends AuthException {
  const ValidationException()
    : super('Please check your email and password format', 'VALIDATION_ERROR');
}

class ServerException extends AuthException {
  const ServerException()
    : super('Server error. Please try again later', 'SERVER_ERROR');
}

class NetworkException extends AuthException {
  const NetworkException()
    : super('Network error. Please check your connection', 'NETWORK_ERROR');
}

class UnknownException extends AuthException {
  const UnknownException(String message) : super(message, 'UNKNOWN_ERROR');
}
