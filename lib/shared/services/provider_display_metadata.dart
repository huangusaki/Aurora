import 'dart:math';

import 'package:aurora/shared/services/gemini_native_endpoint.dart';
import 'package:flutter/material.dart';

class ProviderDisplayMetadata {
  const ProviderDisplayMetadata({
    required this.vendorKey,
    required this.displayColor,
  });

  final String vendorKey;
  final Color displayColor;

  String get displayColorHex => colorToHex(displayColor);
}

ProviderDisplayMetadata resolveProviderDisplayMetadata({
  required String providerId,
  required String baseUrl,
}) {
  final vendorKey = resolveProviderVendorKey(
    providerId: providerId,
    baseUrl: baseUrl,
  );
  return ProviderDisplayMetadata(
    vendorKey: vendorKey,
    displayColor: resolveProviderDisplayColor(vendorKey),
  );
}

String resolveProviderVendorKey({
  required String providerId,
  required String baseUrl,
}) {
  final trimmedBaseUrl = baseUrl.trim();
  final parsed = Uri.tryParse(trimmedBaseUrl);
  final host = (parsed?.host ?? '').trim().toLowerCase();

  if (_isOpenAiHost(host)) return 'openai';
  if (_isAnthropicHost(host)) return 'anthropic';
  if (_isGoogleGeminiHost(host, trimmedBaseUrl)) return 'google-gemini';
  if (host.isNotEmpty) return host;

  final normalizedProviderId = providerId.trim().toLowerCase();
  if (normalizedProviderId.isNotEmpty) {
    return normalizedProviderId;
  }
  return 'unknown-provider';
}

Color resolveProviderDisplayColor(String vendorKey) {
  return _knownVendorColors[vendorKey] ??
      generateStableColorFromString(vendorKey);
}

String colorToHex(Color color) {
  final argb32 = color.toARGB32();
  return '#${argb32.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
}

Color generateStableColorFromString(String input) {
  final normalizedInput = input.trim().toLowerCase();
  final random = Random(normalizedInput.hashCode);
  final hue = random.nextDouble() * 360;
  final saturation = 0.5 + random.nextDouble() * 0.3;
  final lightness = 0.4 + random.nextDouble() * 0.2;
  return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
}

bool _isOpenAiHost(String host) {
  return host == 'openai.com' || host.endsWith('.openai.com');
}

bool _isAnthropicHost(String host) {
  return host == 'anthropic.com' || host.endsWith('.anthropic.com');
}

bool _isGoogleGeminiHost(String host, String baseUrl) {
  return host == 'generativelanguage.googleapis.com' ||
      host == 'aiplatform.googleapis.com' ||
      isOfficialGeminiNativeBaseUrl(baseUrl);
}

const Map<String, Color> _knownVendorColors = {
  'openai': Color(0xFF10A37F),
  'anthropic': Color(0xFFD97706),
  'google-gemini': Color(0xFF4285F4),
};
