import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  final int? statusCode; // Added statusCode to ServerFailure
  const ServerFailure({required String message, this.statusCode})
    : super(message);

  @override
  List<Object> get props => [message, statusCode ?? '']; // Include statusCode in props for Equatable
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class NoInternetFailure extends Failure {
  const NoInternetFailure() : super('No internet connection.');
}

// Add this if it's not already defined in your failures.dart
class DataParsingFailure extends Failure {
  const DataParsingFailure({required String message}) : super(message);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure(String message)
    : super('An unexpected error occurred: $message');
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(String message) : super(message);
}
