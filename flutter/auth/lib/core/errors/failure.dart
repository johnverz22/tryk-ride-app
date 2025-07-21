abstract class Failure {
  final String message;
  final String code;

  const Failure(this.message, this.code);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Failure && other.message == message && other.code == code;
  }

  @override
  int get hashCode => message.hashCode ^ code.hashCode;
}

class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure()
    : super('Invalid email or password', 'INVALID_CREDENTIALS');
}

class ValidationFailure extends Failure {
  const ValidationFailure()
    : super('Please check your email and password format', 'VALIDATION_ERROR');
}

class ServerFailure extends Failure {
  const ServerFailure()
    : super('Server error. Please try again later', 'SERVER_ERROR');
}

class NetworkFailure extends Failure {
  const NetworkFailure()
    : super('Network error. Please check your connection', 'NETWORK_ERROR');
}

class UnknownFailure extends Failure {
  const UnknownFailure(String message) : super(message, 'UNKNOWN_ERROR');
}

class InputValidationFailure extends Failure {
  const InputValidationFailure(String message)
    : super(message, 'INPUT_VALIDATION_ERROR');
}

class LocalStorageFailure extends Failure {
  const LocalStorageFailure()
    : super('Failed to access local storage', 'LOCAL_STORAGE_ERROR');
}
