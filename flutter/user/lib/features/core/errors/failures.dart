import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class NoInternetFailure extends Failure {
  const NoInternetFailure() : super('No internet connection.');
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure(String message)
    : super('An unexpected error occurred: $message');
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(String message) : super(message);
}
