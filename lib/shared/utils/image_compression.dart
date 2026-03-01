import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:aurora/shared/utils/base64_utils.dart';

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
