
enum AppErrorType {
  timeout,
  network,
  badRequest,
  unauthorized,
  serverError,
  rateLimit,
  unknown;

  String get id => name;
}
