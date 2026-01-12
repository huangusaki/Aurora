library;

class DDGSException implements Exception {
  DDGSException(this.message);
  final String message;
  @override
  String toString() => 'DDGSException: $message';
}

class RatelimitException extends DDGSException {
  RatelimitException(super.message);
  @override
  String toString() => 'RatelimitException: $message';
}

class TimeoutException extends DDGSException {
  TimeoutException(super.message);
  @override
  String toString() => 'TimeoutException: $message';
}
