sealed class NetworkException implements Exception {
  const NetworkException(this.message);

  final String message;

  @override
  String toString() => message;
}

class UnauthorizedException extends NetworkException {
  const UnauthorizedException()
    : super('Your session has expired. Please sign in again.');
}

class ServerException extends NetworkException {
  const ServerException(super.message);
}

class NetworkUnavailableException extends NetworkException {
  const NetworkUnavailableException()
    : super('No internet connection. Showing saved data.');
}

class NotFoundException extends NetworkException {
  const NotFoundException()
    : super('The requested SmartVital record was not found.');
}

class TooManyRequestsException extends NetworkException {
  const TooManyRequestsException()
    : super('Too many attempts — try again in 1 minute');
}

class ValidationException extends NetworkException {
  const ValidationException(this.errors)
    : super('Please review the highlighted fields.');

  final Map<String, String> errors;
}
