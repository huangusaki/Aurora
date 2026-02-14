part of '../openai_llm_service.dart';

const Set<String> _supportedVisionImageMimes = {
  'image/jpeg',
  'image/png',
  'image/gif',
  'image/webp',
};

String _normalizeBase64Data(String raw) {
  var normalized = raw.replaceAll(RegExp(r'\s+'), '');
  normalized = normalized.replaceAll('-', '+').replaceAll('_', '/');
  final mod = normalized.length % 4;
  if (mod != 0) {
    normalized = normalized.padRight(normalized.length + (4 - mod), '=');
  }
  return normalized;
}

String? _detectImageMime(Uint8List bytes) {
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0D &&
      bytes[5] == 0x0A &&
      bytes[6] == 0x1A &&
      bytes[7] == 0x0A) {
    return 'image/png';
  }
  if (bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return 'image/jpeg';
  }
  if (bytes.length >= 6 &&
      bytes[0] == 0x47 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x38 &&
      (bytes[4] == 0x37 || bytes[4] == 0x39) &&
      bytes[5] == 0x61) {
    return 'image/gif';
  }
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return 'image/webp';
  }
  if (bytes.length >= 2 && bytes[0] == 0x42 && bytes[1] == 0x4D) {
    return 'image/bmp';
  }
  return null;
}

String? _normalizeImageDataUrl(String url) {
  if (!url.startsWith('data:')) return url;
  final commaIndex = url.indexOf(',');
  if (commaIndex <= 0) return null;
  final header = url.substring(0, commaIndex);
  final rawPayload = url.substring(commaIndex + 1);
  final headerMatch =
      RegExp(r'^data:([^;]+);base64$', caseSensitive: false).firstMatch(header);
  if (headerMatch == null) return null;

  final declaredMime = (headerMatch.group(1) ?? '').toLowerCase();
  if (!declaredMime.startsWith('image/')) return url;

  final payload = _normalizeBase64Data(rawPayload);
  Uint8List bytes;
  try {
    bytes = Uint8List.fromList(base64Decode(payload));
  } catch (_) {
    return null;
  }
  if (bytes.isEmpty) return null;

  final detectedMime = _detectImageMime(bytes);
  if (detectedMime != null &&
      _supportedVisionImageMimes.contains(detectedMime)) {
    return 'data:$detectedMime;base64,${base64Encode(bytes)}';
  }

  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  final transcoded = img.encodeJpg(decoded, quality: 90);
  if (transcoded.isEmpty) return null;
  return 'data:image/jpeg;base64,${base64Encode(transcoded)}';
}

List<Map<String, dynamic>> _sanitizeOutgoingImageMessages(
  List<Map<String, dynamic>> apiMessages, {
  required String selectedModel,
}) {
  final List<Map<String, dynamic>> sanitized = [];
  final isGeminiModel = selectedModel.toLowerCase().contains('gemini');
  for (final msg in apiMessages) {
    final Map<String, dynamic> newMsg = Map<String, dynamic>.from(msg);
    final role = (newMsg['role'] ?? '').toString().toLowerCase();
    final content = newMsg['content'];
    if (content is List) {
      final List<dynamic> newContent = [];
      bool removedImage = false;
      bool removedForGeminiRoleCompat = false;
      for (final item in content) {
        if (item is Map && item['type'] == 'image_url') {
          if (isGeminiModel && role != 'user') {
            // Gemini OpenAI-compatible chat/completions currently rejects
            // non-user image parts and expects assistant parts to be text/refusal.
            removedImage = true;
            removedForGeminiRoleCompat = true;
            continue;
          }
          final imageUrlObj = item['image_url'];
          final url = imageUrlObj is Map ? imageUrlObj['url'] : null;
          if (url is String && url.startsWith('data:')) {
            final normalizedUrl = _normalizeImageDataUrl(url);
            if (normalizedUrl == null) {
              removedImage = true;
              continue;
            }
            final Map<String, dynamic> newItem =
                Map<String, dynamic>.from(item);
            if (imageUrlObj is Map) {
              final newImageUrlObj = Map<String, dynamic>.from(imageUrlObj);
              newImageUrlObj['url'] = normalizedUrl;
              newItem['image_url'] = newImageUrlObj;
            } else {
              newItem['image_url'] = {'url': normalizedUrl};
            }
            newContent.add(newItem);
            continue;
          }
        }
        newContent.add(item);
      }
      if (newContent.isEmpty && removedImage) {
        if (removedForGeminiRoleCompat) {
          newMsg['content'] =
              '[Image omitted: unsupported in non-user role for Gemini compatibility]';
        } else {
          newMsg['content'] = '[Image omitted: invalid or unsupported format]';
        }
      } else {
        newMsg['content'] = newContent;
      }
    }
    sanitized.add(newMsg);
  }
  return sanitized;
}

Future<List<Map<String, dynamic>>> _compressImagesTask(
    List<Map<String, dynamic>> apiMessages) async {
  String? compressSingleImage(Uint8List bytes) {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return null;
      int targetWidth = image.width;
      int targetHeight = image.height;
      if (targetWidth > 1920 || targetHeight > 1080) {
        final aspectRatio = targetWidth / targetHeight;
        if (aspectRatio > 1920 / 1080) {
          targetWidth = 1920;
          targetHeight = (1920 / aspectRatio).round();
        } else {
          targetHeight = 1080;
          targetWidth = (1080 * aspectRatio).round();
        }
      }
      final resized =
          (targetWidth != image.width || targetHeight != image.height)
              ? img.copyResize(image, width: targetWidth, height: targetHeight)
              : image;
      final compressed = img.encodeJpg(resized, quality: 85);
      return base64Encode(compressed);
    } catch (e) {
      return base64Encode(bytes);
    }
  }

  final List<Map<String, dynamic>> result = [];
  for (final msg in apiMessages) {
    final Map<String, dynamic> newMsg = Map.from(msg);
    final content = newMsg['content'];
    if (content is List) {
      final List<dynamic> newContentList = [];
      for (final item in content) {
        if (item is Map && item['type'] == 'image_url') {
          final imageUrl = item['image_url']?['url'];
          if (imageUrl is String && imageUrl.startsWith('data:')) {
            final commaIndex = imageUrl.indexOf(',');
            if (commaIndex != -1) {
              final header = imageUrl.substring(0, commaIndex);
              final mimeType = header.split(':')[1].split(';')[0];

              // Only attempt to compress if it's an image
              if (mimeType.startsWith('image/')) {
                try {
                  final bytes =
                      base64Decode(imageUrl.substring(commaIndex + 1));
                  final compressed =
                      compressSingleImage(Uint8List.fromList(bytes));
                  if (compressed == null) {
                    newContentList.add(item);
                    continue;
                  }
                  newContentList.add({
                    'type': 'image_url',
                    'image_url': {
                      'url': 'data:image/jpeg;base64,$compressed',
                    },
                    if (item.containsKey('thought_signature'))
                      'thought_signature': item['thought_signature'],
                  });
                  continue;
                } catch (e) {
                  newContentList.add(item);
                  continue;
                }
              }
            }
          }
        }
        newContentList.add(item);
      }
      newMsg['content'] = newContentList;
    }
    result.add(newMsg);
  }
  return result;
}
