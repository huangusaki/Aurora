library;

import 'dart:convert';
import 'exceptions.dart';

String normalizeText(String text) =>
    text.trim().replaceAll(RegExp(r'\s+'), ' ');
String normalizeUrl(String url) => url.trim();
String normalizeDate(String date) => date.trim();
String? expandProxyTbAlias(String? proxy) {
  if (proxy == 'tb') {
    return 'socks5h://127.0.0.1:9150';
  }
  return proxy;
}

String jsonEncode(Object? obj) {
  try {
    return const JsonEncoder.withIndent('  ').convert(obj);
  } catch (e) {
    throw AuroraSearchException('JSON encode error: $e');
  }
}

dynamic jsonDecode(String str) {
  try {
    return json.decode(str);
  } catch (e) {
    throw AuroraSearchException('JSON decode error: $e');
  }
}

String? extractVqd(String htmlContent, String query) {
  var match = RegExp('vqd="([^"]+)"').firstMatch(htmlContent);
  if (match != null) {
    return match.group(1);
  }
  match = RegExp('vqd=([^&]+)&').firstMatch(htmlContent);
  if (match != null) {
    return match.group(1);
  }
  return null;
}
