import 'dart:convert';
import 'dart:typed_data';

final RegExp _whitespaceAny = RegExp(r'\s');
final RegExp _whitespaceRun = RegExp(r'\s+');

/// Normalizes a Base64 (or Base64URL) payload so [base64Decode] accepts it:
/// - trims and removes all whitespace
/// - converts Base64URL to standard Base64
/// - adds '=' padding to a length multiple of 4
String normalizeBase64Payload(String raw) {
  var normalized = raw.trim();
  if (normalized.isEmpty) return normalized;

  if (normalized.contains(_whitespaceAny)) {
    normalized = normalized.replaceAll(_whitespaceRun, '');
  }

  // Base64URL -> Base64
  if (normalized.contains('-') || normalized.contains('_')) {
    normalized = normalized.replaceAll('-', '+').replaceAll('_', '/');
  }

  final mod = normalized.length % 4;
  if (mod != 0) {
    normalized = normalized.padRight(normalized.length + (4 - mod), '=');
  }

  return normalized;
}

Uint8List decodeBase64Lenient(String raw) {
  final normalized = normalizeBase64Payload(raw);
  return base64Decode(normalized);
}

Uint8List decodeDataUrlBytesLenient(String dataUrl) {
  if (!dataUrl.startsWith('data:')) {
    return decodeBase64Lenient(dataUrl);
  }
  final commaIndex = dataUrl.indexOf(',');
  if (commaIndex < 0) {
    throw const FormatException('Invalid data URL: missing comma');
  }
  final payload = dataUrl.substring(commaIndex + 1);
  return decodeBase64Lenient(payload);
}
