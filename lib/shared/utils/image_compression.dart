import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:aurora/shared/utils/base64_utils.dart';

bool _startsWithImageMagic(Uint8List bytes) {
  if (bytes.isEmpty) return false;
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0D &&
      bytes[5] == 0x0A &&
      bytes[6] == 0x1A &&
      bytes[7] == 0x0A) {
    return true; // PNG
  }
  if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
    return true; // JPEG
  }
  if (bytes.length >= 6 &&
      bytes[0] == 0x47 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x38 &&
      (bytes[4] == 0x37 || bytes[4] == 0x39) &&
      bytes[5] == 0x61) {
    return true; // GIF
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
    return true; // WEBP
  }
  if (bytes.length >= 2 && bytes[0] == 0x42 && bytes[1] == 0x4D) {
    return true; // BMP
  }
  if (bytes.length >= 4 &&
      ((bytes[0] == 0x49 && bytes[1] == 0x49 && bytes[2] == 0x2A && bytes[3] == 0x00) ||
          (bytes[0] == 0x4D && bytes[1] == 0x4D && bytes[2] == 0x00 && bytes[3] == 0x2A))) {
    return true; // TIFF
  }
  return false;
}

Uint8List? _tryDecodeDataUrlPrefix(String dataUrl, {int maxPayloadChars = 256}) {
  final commaIndex = dataUrl.indexOf(',');
  if (commaIndex <= 0) return null;
  final payload = dataUrl.substring(commaIndex + 1).trim();
  if (payload.isEmpty) return null;
  final sample = payload.length <= maxPayloadChars
      ? payload
      : payload.substring(0, maxPayloadChars);
  try {
    return decodeBase64Lenient(sample);
  } catch (_) {
    return null;
  }
}

bool isLikelyImageDataUrl(String dataUrl) {
  if (!dataUrl.startsWith('data:')) return false;
  final commaIndex = dataUrl.indexOf(',');
  if (commaIndex <= 0) return false;
  final header = dataUrl.substring(0, commaIndex).toLowerCase();
  if (!header.startsWith('data:image/')) return false;
  if (!header.contains(';base64')) return false;
  final prefixBytes = _tryDecodeDataUrlPrefix(dataUrl);
  if (prefixBytes == null || prefixBytes.isEmpty) return false;
  return _startsWithImageMagic(prefixBytes);
}

/// Removes duplicates and drops malformed/chunked `data:image/*;base64,...` URLs.
/// Keeps non-data URLs (http/local file paths) as-is.
List<String> sanitizeImageUrls(List<String> urls) {
  if (urls.isEmpty) return const [];
  final output = <String>[];
  final seen = <String>{};
  for (final raw in urls) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) continue;
    if (!seen.add(trimmed)) continue;
    if (trimmed.startsWith('data:') && !isLikelyImageDataUrl(trimmed)) {
      continue;
    }
    output.add(trimmed);
  }
  return output;
}

String _compressImageDataUrlSync(String dataUrl) {
  if (!dataUrl.startsWith('data:')) return dataUrl;

  final commaIndex = dataUrl.indexOf(',');
  if (commaIndex <= 0) return dataUrl;

  final header = dataUrl.substring(0, commaIndex);
  final payload = dataUrl.substring(commaIndex + 1);

  // 提取 MIME 类型
  final colonIndex = header.indexOf(':');
  final semicolonIndex = header.indexOf(';');
  if (colonIndex < 0 || semicolonIndex < 0) return dataUrl;
  final mimeType = header.substring(colonIndex + 1, semicolonIndex);

  // 只处理图片
  if (!mimeType.startsWith('image/')) return dataUrl;

  // 体积合理，跳过（避免不必要的转码/降质）
  if (payload.length < 10 * 1024 * 1024) {
    return dataUrl;
  }

  try {
    final sw = Stopwatch()..start();
    final cleanPayload = normalizeBase64Payload(payload);
    final bytes = base64Decode(cleanPayload);
    debugPrint('[IMAGE_COMPRESS] Decoded ${cleanPayload.length} chars to ${bytes.length} bytes');
    
    final image = img.decodeImage(bytes);
    if (image == null) {
      debugPrint('[IMAGE_COMPRESS] Decode failed, returning original');
      return dataUrl;
    }

    final jpegBytes = img.encodeJpg(image, quality: 95);
    final jpegBase64 = base64Encode(jpegBytes);
    final result = 'data:image/jpeg;base64,$jpegBase64';
    
    debugPrint('[IMAGE_COMPRESS] Compressed ${payload.length} -> ${jpegBase64.length} chars (${(jpegBase64.length / payload.length * 100).toStringAsFixed(1)}%) in ${sw.elapsedMilliseconds}ms');
    return result;
  } catch (e) {
    debugPrint('[IMAGE_COMPRESS] Error during compression: $e');
    return dataUrl;
  }
}
Future<String> compressImageDataUrl(String dataUrl) {
  // 绝大多数图片无需压缩（避免不必要的 Isolate 序列化/拷贝开销）
  if (dataUrl.length < 10 * 1024 * 1024) {
    return Future.value(dataUrl);
  }
  return compute(_compressImageDataUrlSync, dataUrl);
}

/// 批量压缩多张图片，并行执行。
Future<List<String>> compressImageDataUrls(List<String> dataUrls) {
  return Future.wait(dataUrls.map(compressImageDataUrl));
}

/// 从 data URL 中提取 MIME 类型，用于确定保存时的文件扩展名。
/// 如果无法解析则返回 null。
String? extractMimeFromDataUrl(String dataUrl) {
  if (!dataUrl.startsWith('data:')) return null;
  final commaIndex = dataUrl.indexOf(',');
  if (commaIndex <= 0) return null;
  final header = dataUrl.substring(0, commaIndex);
  final colonIndex = header.indexOf(':');
  final semicolonIndex = header.indexOf(';');
  if (colonIndex < 0 || semicolonIndex < 0) return null;
  return header.substring(colonIndex + 1, semicolonIndex);
}

/// 根据 MIME 类型返回合适的文件扩展名。
String extensionForMime(String? mime) {
  switch (mime) {
    case 'image/jpeg':
    case 'image/jpg':
      return 'jpg';
    case 'image/webp':
      return 'webp';
    case 'image/gif':
      return 'gif';
    case 'image/png':
    default:
      return 'png';
  }
}
