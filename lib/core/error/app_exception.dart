import 'app_error_type.dart';

class AppException implements Exception {
  final AppErrorType type;
  final String message;
  final int? statusCode;

  AppException({
    required this.type,
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => message;
}
