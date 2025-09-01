abstract class Failure {
  const Failure();
}

class ServerFailure extends Failure {}

class NetworkFailure extends Failure {}

class CacheFailure extends Failure {}

class AuthFailure extends Failure {}