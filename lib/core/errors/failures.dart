/// Base Failure class for Clean Architecture error handling.
abstract class Failure {
  final String message;
  final int? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => 'Failure(message: $message, code: $code)';
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'A server error occurred.']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'A local storage error occurred.']);
}

class DeviceSensorFailure extends Failure {
  const DeviceSensorFailure([super.message = 'Unable to access device sensors.']);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Required permission was denied.']);
}
