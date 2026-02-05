library;

class AuroraSearchException implements Exception {
  AuroraSearchException(this.message);
  final String message;
  @override
  String toString() => 'AuroraSearchException: $message';
}

class AuroraSearchRateLimitException extends AuroraSearchException {
  AuroraSearchRateLimitException(super.message);
  @override
  String toString() => 'AuroraSearchRateLimitException: $message';
}

class AuroraSearchTimeoutException extends AuroraSearchException {
  AuroraSearchTimeoutException(super.message);
  @override
  String toString() => 'AuroraSearchTimeoutException: $message';
}
