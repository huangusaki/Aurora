import 'dart:io';
import 'dart:typed_data';

import 'package:isar_community/isar.dart';
import 'package:path/path.dart' as p;

import 'package:aurora/features/chat/data/message_entity.dart';
import 'package:aurora/shared/utils/base64_utils.dart';

import 'aurora_isar_tooling.dart';

class _Options {
  const _Options({
    required this.dbDir,
    required this.apply,
    required this.dropAllDataUrls,
    required this.stripDataUrlsInText,
    required this.mergeLooseBase64Chunks,
    required this.purgeLooseBase64Text,
    required this.batchSize,
  });

  final String? dbDir;
  final bool apply;
  final bool dropAllDataUrls;
  final bool stripDataUrlsInText;
  final bool mergeLooseBase64Chunks;
  final bool purgeLooseBase64Text;
  final int batchSize;
}

class _ImageCleanStats {
  int droppedEmpty = 0;
  int droppedInvalidDataUrls = 0;
  int droppedBase64Chunks = 0;
  int droppedAllDataUrls = 0;
  int mergedChunkedDataUrls = 0;
  int mergedPrefixDuplicates = 0;
}

class _TextStripStats {
  int occurrences = 0;
  int removedChars = 0;
}

class _LooseBase64PurgeStats {
  int sessionIdCleared = 0;
  int assistantIdCleared = 0;
  int requestIdCleared = 0;
  int modelCleared = 0;
  int providerCleared = 0;
  int roleCleared = 0;
  int toolCallIdCleared = 0;
  int reasoningCleared = 0;
  int toolCallsCleared = 0;
  int contentCleared = 0;
}

class _WriteApplyStats {
  int attempted = 0;
  int written = 0;
  int skippedTooLarge = 0;
  int fallbackDropDataAttachments = 0;
  int fallbackDropAllAttachments = 0;
  int fallbackDropDataImages = 0;
  int fallbackDropAllImages = 0;
  int fallbackClearMetaFields = 0;
  int fallbackClearReasoning = 0;
  int fallbackClearToolCalls = 0;
  int fallbackClearContent = 0;
}

void _printUsage() {
  stdout.writeln('Aurora Isar 聊天图片清理脚本');
  stdout.writeln('');
  stdout.writeln('用法:');
  stdout.writeln('  dart run tools/clean_aurora_db_images.dart [选项]');
  stdout.writeln('');
  stdout.writeln('常用示例:');
  stdout.writeln(r'  dart run tools/clean_aurora_db_images.dart --apply');
  stdout.writeln(
      r'  dart run tools/clean_aurora_db_images.dart --apply --db-dir "C:\Users\<你>\AppData\Roaming\Aurora"');
  stdout.writeln(
      r'  dart run tools/clean_aurora_db_images.dart --apply --drop-data-urls   (会删除所有 data: 图片/附件)');
  stdout.writeln('');
  stdout.writeln('选项:');
  stdout.writeln(
      '  --db-dir <目录>            Aurora 数据目录(包含 default.isar)。不填则自动尝试查找。');
  stdout.writeln('  --apply                    实际写入数据库(默认仅 dry-run 统计，不改数据)。');
  stdout.writeln(
      '  --drop-data-urls            删除 images/attachments 里所有以 data: 开头的条目(包括正常图片)。');
  stdout.writeln(
      '  --strip-text               同时从 content/reasoning/toolCallsJson 中剥离 data:image/...;base64,...');
  stdout.writeln(
      '  --purge-loose-base64        清空明显异常的大块字段(含 sessionId/requestId/model/provider/role/reasoning 等)。');
  stdout.writeln(
      '  --merge-loose-base64-chunks 尝试把“无 data: 头的 base64 块”拼到上一张 data:image(通常体积不会变小)。');
  stdout.writeln('  --batch-size <N>           扫描批大小(默认 200)。');
  stdout.writeln('  -h, --help                 显示帮助。');
}

_Options _parseArgs(List<String> args) {
  String? dbDir;
  var apply = false;
  var dropAllDataUrls = false;
  var stripDataUrlsInText = false;
  var purgeLooseBase64Text = false;
  var mergeLooseBase64Chunks = false;
  var batchSize = 200;

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '-h' || a == '--help') {
      _printUsage();
      exit(0);
    } else if (a == '--apply') {
      apply = true;
    } else if (a == '--dry-run') {
      apply = false;
    } else if (a == '--drop-data-urls') {
      dropAllDataUrls = true;
    } else if (a == '--strip-text') {
      stripDataUrlsInText = true;
    } else if (a == '--purge-loose-base64') {
      purgeLooseBase64Text = true;
    } else if (a == '--merge-loose-base64-chunks') {
      mergeLooseBase64Chunks = true;
    } else if (a.startsWith('--db-dir=')) {
      dbDir = a.substring('--db-dir='.length).trim().replaceAll('"', '');
    } else if (a == '--db-dir') {
      if (i + 1 >= args.length) {
        stderr.writeln('缺少 --db-dir 的参数值');
        exit(2);
      }
      dbDir = args[++i];
    } else if (a.startsWith('--batch-size=')) {
      final raw = a.substring('--batch-size='.length);
      batchSize = int.tryParse(raw) ?? batchSize;
    } else if (a == '--batch-size') {
      if (i + 1 >= args.length) {
        stderr.writeln('缺少 --batch-size 的参数值');
        exit(2);
      }
      batchSize = int.tryParse(args[++i]) ?? batchSize;
    } else {
      stderr.writeln('未知参数: $a');
      stderr.writeln('');
      _printUsage();
      exit(2);
    }
  }

  if (batchSize <= 0) batchSize = 200;
  if (batchSize > 5000) batchSize = 5000;

  return _Options(
    dbDir: dbDir,
    apply: apply,
    dropAllDataUrls: dropAllDataUrls,
    stripDataUrlsInText: stripDataUrlsInText,
    mergeLooseBase64Chunks: mergeLooseBase64Chunks,
    purgeLooseBase64Text: purgeLooseBase64Text,
    batchSize: batchSize,
  );
}

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
  if (bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
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
      ((bytes[0] == 0x49 &&
              bytes[1] == 0x49 &&
              bytes[2] == 0x2A &&
              bytes[3] == 0x00) ||
          (bytes[0] == 0x4D &&
              bytes[1] == 0x4D &&
              bytes[2] == 0x00 &&
              bytes[3] == 0x2A))) {
    return true; // TIFF
  }
  return false;
}

Uint8List? _tryDecodeDataUrlPrefix(String dataUrl,
    {int maxPayloadChars = 256}) {
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

bool _isLikelyImageDataUrl(String dataUrl) {
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

bool _looksLikeLooseBase64Chunk(String s) {
  // Heuristic: a very long string containing only base64/base64url chars is
  // almost certainly an accidental streamed image chunk.
  if (s.length < 512) return false;
  // Quick rejection for common path/url markers.
  if (s.contains('://') ||
      s.contains('\\') ||
      s.contains(':') ||
      s.contains('.') ||
      s.contains('%')) {
    return false;
  }
  final maxCheck = s.length < 4096 ? s.length : 4096;
  for (var i = 0; i < maxCheck; i++) {
    final c = s.codeUnitAt(i);
    final isUpper = c >= 0x41 && c <= 0x5A;
    final isLower = c >= 0x61 && c <= 0x7A;
    final isDigit = c >= 0x30 && c <= 0x39;
    final isAllowed = isUpper ||
        isLower ||
        isDigit ||
        c == 0x2B || // +
        c == 0x2F || // /
        c == 0x3D || // =
        c == 0x2D || // -
        c == 0x5F || // _
        c == 0x20 || // space
        c == 0x09 || // tab
        c == 0x0A || // lf
        c == 0x0D; // cr
    if (!isAllowed) return false;
  }
  return true;
}

bool _isSuspiciousMetaFieldValue(
  String? value, {
  required int maxLen,
}) {
  if (value == null) return false;
  final trimmed = value.trim();
  if (trimmed.isEmpty) return false;
  if (trimmed.length > maxLen) return true;
  if (trimmed.contains('data:image/')) return true;
  return _looksLikeLooseBase64Chunk(trimmed);
}

int _clearSuspiciousMetaFields(MessageEntity message) {
  var cleared = 0;
  if (_isSuspiciousMetaFieldValue(message.sessionId, maxLen: 200)) {
    message.sessionId = null;
    cleared++;
  }
  if (_isSuspiciousMetaFieldValue(message.assistantId, maxLen: 512)) {
    message.assistantId = null;
    cleared++;
  }
  if (_isSuspiciousMetaFieldValue(message.requestId, maxLen: 1024)) {
    message.requestId = null;
    cleared++;
  }
  if (_isSuspiciousMetaFieldValue(message.model, maxLen: 512)) {
    message.model = null;
    cleared++;
  }
  if (_isSuspiciousMetaFieldValue(message.provider, maxLen: 256)) {
    message.provider = null;
    cleared++;
  }
  if (_isSuspiciousMetaFieldValue(message.role, maxLen: 64)) {
    message.role = null;
    cleared++;
  }
  if (_isSuspiciousMetaFieldValue(message.toolCallId, maxLen: 512)) {
    message.toolCallId = null;
    cleared++;
  }
  return cleared;
}

List<String> _cleanImages(
  List<String> images,
  _Options opts,
  _ImageCleanStats stats,
) {
  if (images.isEmpty) return const [];

  final output = <String>[];
  final seenExact = <String>{};

  for (final raw in images) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      stats.droppedEmpty++;
      continue;
    }

    if (opts.dropAllDataUrls && trimmed.startsWith('data:')) {
      stats.droppedAllDataUrls++;
      continue;
    }

    if (!trimmed.startsWith('data:') && _looksLikeLooseBase64Chunk(trimmed)) {
      if (opts.mergeLooseBase64Chunks &&
          output.isNotEmpty &&
          output.last.startsWith('data:image/') &&
          output.last.contains(';base64,')) {
        output[output.length - 1] = '${output.last}$trimmed';
        stats.mergedChunkedDataUrls++;
      } else {
        stats.droppedBase64Chunks++;
      }
      continue;
    }

    if (trimmed.startsWith('data:')) {
      final commaIndex = trimmed.indexOf(',');
      final header = commaIndex > 0 ? trimmed.substring(0, commaIndex) : '';
      final lowerHeader = header.toLowerCase();
      final isBase64Image = lowerHeader.startsWith('data:image/') &&
          lowerHeader.contains(';base64');

      if (isBase64Image && !_isLikelyImageDataUrl(trimmed)) {
        // Attempt to merge chunked packets that repeat the same header.
        final payload =
            commaIndex > 0 ? trimmed.substring(commaIndex + 1).trim() : '';
        var mergedIntoExisting = false;
        if (payload.isNotEmpty) {
          for (var i = output.length - 1; i >= 0; i--) {
            final existing = output[i];
            if (!existing.startsWith('data:')) continue;
            final existingComma = existing.indexOf(',');
            if (existingComma <= 0) continue;
            final existingHeader = existing.substring(0, existingComma);
            if (existingHeader.toLowerCase() != lowerHeader) continue;
            final existingPayload = existing.substring(existingComma + 1);
            if (!existingPayload.endsWith(payload)) {
              output[i] = '$existingHeader,${existingPayload + payload}';
            }
            stats.mergedChunkedDataUrls++;
            mergedIntoExisting = true;
            break;
          }
        }
        if (!mergedIntoExisting) {
          stats.droppedInvalidDataUrls++;
        }
        continue;
      }
    }

    if (!seenExact.add(trimmed)) {
      continue;
    }

    bool merged = false;
    if (trimmed.startsWith('data:')) {
      // Prefix-based merge to keep only the most complete streamed data URL.
      for (var i = 0; i < output.length; i++) {
        final existing = output[i];
        if (!existing.startsWith('data:')) continue;
        if (trimmed.startsWith(existing)) {
          output[i] = trimmed;
          stats.mergedPrefixDuplicates++;
          merged = true;
          break;
        }
        if (existing.startsWith(trimmed)) {
          stats.mergedPrefixDuplicates++;
          merged = true;
          break;
        }
      }
    }
    if (!merged) {
      output.add(trimmed);
    }
  }

  return output;
}

bool _isBase64PayloadChar(int c) {
  final isUpper = c >= 0x41 && c <= 0x5A;
  final isLower = c >= 0x61 && c <= 0x7A;
  final isDigit = c >= 0x30 && c <= 0x39;
  return isUpper ||
      isLower ||
      isDigit ||
      c == 0x2B || // +
      c == 0x2F || // /
      c == 0x3D || // =
      c == 0x2D || // -
      c == 0x5F; // _
}

String _stripDataImageUrls(String input, _TextStripStats stats) {
  var s = input;
  var start = s.indexOf('data:image/');
  while (start >= 0) {
    final base64Marker = s.indexOf(';base64,', start);
    if (base64Marker < 0) {
      start = s.indexOf('data:image/', start + 10);
      continue;
    }
    final commaIndex = base64Marker + ';base64,'.length - 1; // points to comma
    final payloadStart = commaIndex + 1;
    if (payloadStart >= s.length) break;

    var end = payloadStart;
    while (end < s.length && _isBase64PayloadChar(s.codeUnitAt(end))) {
      end++;
    }
    if (end == payloadStart) {
      start = s.indexOf('data:image/', start + 10);
      continue;
    }

    final header = s.substring(start, payloadStart);
    final replacement = '${header}__omitted__';
    stats.occurrences++;
    stats.removedChars += (end - start) - replacement.length;
    s = s.replaceRange(start, end, replacement);
    start = s.indexOf('data:image/', start + replacement.length);
  }
  return s;
}

bool _isTooLargeObjectError(Object error) {
  final lower = error.toString().toLowerCase();
  return lower.contains('object is bigger than 16mb');
}

int _estimateMessageChars(MessageEntity message) {
  var total = 0;
  total += message.content.length;
  total += message.reasoningContent?.length ?? 0;
  total += message.sessionId?.length ?? 0;
  total += message.assistantId?.length ?? 0;
  total += message.requestId?.length ?? 0;
  total += message.model?.length ?? 0;
  total += message.provider?.length ?? 0;
  total += message.role?.length ?? 0;
  total += message.toolCallId?.length ?? 0;
  total += message.toolCallsJson?.length ?? 0;
  total += message.attachments.fold<int>(0, (sum, v) => sum + v.length);
  total += message.images.fold<int>(0, (sum, v) => sum + v.length);
  return total;
}

Future<bool> _putMessageWithFallback({
  required Isar isar,
  required MessageEntity message,
  required _WriteApplyStats stats,
}) async {
  Future<void> tryPut() async {
    await isar.writeTxn(() async {
      await isar.messageEntitys.put(message);
    });
  }

  stats.attempted++;
  try {
    await tryPut();
    stats.written++;
    return true;
  } catch (e) {
    if (!_isTooLargeObjectError(e)) rethrow;
  }

  final noDataAttachments =
      message.attachments.where((v) => !v.trim().startsWith('data:')).toList();
  if (noDataAttachments.length != message.attachments.length) {
    message.attachments = noDataAttachments;
    stats.fallbackDropDataAttachments++;
    try {
      await tryPut();
      stats.written++;
      return true;
    } catch (e) {
      if (!_isTooLargeObjectError(e)) rethrow;
    }
  }

  final noDataImages =
      message.images.where((v) => !v.trim().startsWith('data:')).toList();
  if (noDataImages.length != message.images.length) {
    message.images = noDataImages;
    stats.fallbackDropDataImages++;
    try {
      await tryPut();
      stats.written++;
      return true;
    } catch (e) {
      if (!_isTooLargeObjectError(e)) rethrow;
    }
  }

  if (message.attachments.isNotEmpty) {
    message.attachments = const [];
    stats.fallbackDropAllAttachments++;
    try {
      await tryPut();
      stats.written++;
      return true;
    } catch (e) {
      if (!_isTooLargeObjectError(e)) rethrow;
    }
  }

  if (message.images.isNotEmpty) {
    message.images = const [];
    stats.fallbackDropAllImages++;
    try {
      await tryPut();
      stats.written++;
      return true;
    } catch (e) {
      if (!_isTooLargeObjectError(e)) rethrow;
    }
  }

  final clearedMeta = _clearSuspiciousMetaFields(message);
  if (clearedMeta > 0) {
    stats.fallbackClearMetaFields += clearedMeta;
    try {
      await tryPut();
      stats.written++;
      return true;
    } catch (e) {
      if (!_isTooLargeObjectError(e)) rethrow;
    }
  }

  if (message.reasoningContent != null &&
      message.reasoningContent!.isNotEmpty) {
    message.reasoningContent = null;
    stats.fallbackClearReasoning++;
  }
  if (message.toolCallsJson != null && message.toolCallsJson!.isNotEmpty) {
    message.toolCallsJson = null;
    stats.fallbackClearToolCalls++;
  }
  if (_looksLikeLooseBase64Chunk(message.content) ||
      message.content.length > 4 * 1024 * 1024) {
    message.content = '';
    stats.fallbackClearContent++;
  }

  try {
    await tryPut();
    stats.written++;
    return true;
  } catch (e) {
    if (!_isTooLargeObjectError(e)) rethrow;
    stats.skippedTooLarge++;
    stderr.writeln(
      '跳过超大消息 id=${message.id} (估算chars=${_estimateMessageChars(message)}): 仍超过 Isar 16MB 限制',
    );
    return false;
  }
}

Future<void> main(List<String> args) async {
  final opts = _parseArgs(args);

  var dbDir = opts.dbDir?.trim();
  if (dbDir == null || dbDir.isEmpty) {
    dbDir = autoDetectAuroraDbDir();
  }
  if (dbDir == null || dbDir.isEmpty) {
    stderr.writeln('找不到 Aurora 数据目录。请手动指定: --db-dir "<包含 default.isar 的目录>"');
    exit(2);
  }

  final dir = Directory(dbDir);
  if (!dir.existsSync()) {
    stderr.writeln('目录不存在: $dbDir');
    exit(2);
  }

  final isarFile = File(p.join(dbDir, 'default.isar'));
  if (!isarFile.existsSync()) {
    stderr.writeln('未找到数据库文件: ${isarFile.path}');
    stderr.writeln('请确认 --db-dir 指向包含 default.isar 的目录。');
    exit(2);
  }

  final lockFile = File(p.join(dbDir, 'default.isar.lock'));
  if (lockFile.existsSync()) {
    stderr.writeln('检测到 ${lockFile.path}，Aurora 可能仍在运行。建议先关闭 Aurora 再执行清理。');
  }

  stdout.writeln('DB: $dbDir');
  stdout.writeln('Mode: ${opts.apply ? 'APPLY(写入)' : 'DRY-RUN(仅统计)'}');
  if (opts.dropAllDataUrls) {
    stdout.writeln('Option: --drop-data-urls (会删除所有 data: 图片/附件)');
  }
  if (opts.stripDataUrlsInText) {
    stdout.writeln('Option: --strip-text (会修改聊天文本字段)');
  }
  if (opts.purgeLooseBase64Text) {
    stdout.writeln('Option: --purge-loose-base64 (会清空明显异常的大块字段，含元数据字段)');
  }
  if (opts.mergeLooseBase64Chunks) {
    stdout.writeln('Option: --merge-loose-base64-chunks');
  }
  stdout.writeln('Batch size: ${opts.batchSize}');
  stdout.writeln('');

  final sw = Stopwatch()..start();

  await ensureIsarCoreLoaded();

  final isar = await Isar.open(
    auroraIsarSchemas,
    directory: dbDir,
  );

  var scanned = 0;
  var modified = 0;
  var persisted = 0;
  var skipped = 0;

  var totalImagesCountBefore = 0;
  var totalImagesCountAfter = 0;
  var totalImagesCharsBefore = 0;
  var totalImagesCharsAfter = 0;
  var totalAttachmentsCountBefore = 0;
  var totalAttachmentsCountAfter = 0;
  var totalAttachmentsCharsBefore = 0;
  var totalAttachmentsCharsAfter = 0;

  final imageStats = _ImageCleanStats();
  final attachmentStats = _ImageCleanStats();
  final textStats = _TextStripStats();
  final base64PurgeStats = _LooseBase64PurgeStats();
  final writeStats = _WriteApplyStats();

  var lastId = 0;
  while (true) {
    // Always scan all messages so attachments bloat can also be cleaned.
    final query =
        isar.messageEntitys.where().idGreaterThan(lastId).limit(opts.batchSize);

    final batch = await query.findAll();
    if (batch.isEmpty) break;

    lastId = batch.last.id;
    final toUpdate = <MessageEntity>[];

    for (final m in batch) {
      scanned++;

      final beforeImages = List<String>.from(m.images);
      final beforeImagesChars =
          beforeImages.fold<int>(0, (sum, s) => sum + s.length);
      final beforeAttachments = List<String>.from(m.attachments);
      final beforeAttachmentsChars =
          beforeAttachments.fold<int>(0, (sum, s) => sum + s.length);

      final cleanedImages = _cleanImages(beforeImages, opts, imageStats);
      final afterImagesChars =
          cleanedImages.fold<int>(0, (sum, s) => sum + s.length);
      final cleanedAttachments =
          _cleanImages(beforeAttachments, opts, attachmentStats);
      final afterAttachmentsChars =
          cleanedAttachments.fold<int>(0, (sum, s) => sum + s.length);

      totalImagesCountBefore += beforeImages.length;
      totalImagesCountAfter += cleanedImages.length;
      totalImagesCharsBefore += beforeImagesChars;
      totalImagesCharsAfter += afterImagesChars;
      totalAttachmentsCountBefore += beforeAttachments.length;
      totalAttachmentsCountAfter += cleanedAttachments.length;
      totalAttachmentsCharsBefore += beforeAttachmentsChars;
      totalAttachmentsCharsAfter += afterAttachmentsChars;

      var changed = false;
      if (!_listEquals(beforeImages, cleanedImages)) {
        m.images = cleanedImages;
        changed = true;
      }
      if (!_listEquals(beforeAttachments, cleanedAttachments)) {
        m.attachments = cleanedAttachments;
        changed = true;
      }

      if (opts.stripDataUrlsInText) {
        final newContent = _stripDataImageUrls(m.content, textStats);
        if (newContent != m.content) {
          m.content = newContent;
          changed = true;
        }
        final reasoning = m.reasoningContent;
        if (reasoning != null && reasoning.contains('data:image/')) {
          final newReasoning = _stripDataImageUrls(reasoning, textStats);
          if (newReasoning != reasoning) {
            m.reasoningContent = newReasoning;
            changed = true;
          }
        }
        final toolCallsJson = m.toolCallsJson;
        if (toolCallsJson != null && toolCallsJson.contains('data:image/')) {
          final newToolCallsJson =
              _stripDataImageUrls(toolCallsJson, textStats);
          if (newToolCallsJson != toolCallsJson) {
            m.toolCallsJson = newToolCallsJson;
            changed = true;
          }
        }
      }

      if (opts.purgeLooseBase64Text) {
        if (_isSuspiciousMetaFieldValue(m.sessionId, maxLen: 200)) {
          m.sessionId = null;
          base64PurgeStats.sessionIdCleared++;
          changed = true;
        }
        if (_isSuspiciousMetaFieldValue(m.assistantId, maxLen: 512)) {
          m.assistantId = null;
          base64PurgeStats.assistantIdCleared++;
          changed = true;
        }
        if (_isSuspiciousMetaFieldValue(m.requestId, maxLen: 1024)) {
          m.requestId = null;
          base64PurgeStats.requestIdCleared++;
          changed = true;
        }
        if (_isSuspiciousMetaFieldValue(m.model, maxLen: 512)) {
          m.model = null;
          base64PurgeStats.modelCleared++;
          changed = true;
        }
        if (_isSuspiciousMetaFieldValue(m.provider, maxLen: 256)) {
          m.provider = null;
          base64PurgeStats.providerCleared++;
          changed = true;
        }
        if (_isSuspiciousMetaFieldValue(m.role, maxLen: 64)) {
          m.role = null;
          base64PurgeStats.roleCleared++;
          changed = true;
        }
        if (_isSuspiciousMetaFieldValue(m.toolCallId, maxLen: 512)) {
          m.toolCallId = null;
          base64PurgeStats.toolCallIdCleared++;
          changed = true;
        }
        final reasoning = m.reasoningContent;
        if (reasoning != null && _looksLikeLooseBase64Chunk(reasoning)) {
          m.reasoningContent = null;
          base64PurgeStats.reasoningCleared++;
          changed = true;
        }
        final tools = m.toolCallsJson;
        if (tools != null && _looksLikeLooseBase64Chunk(tools)) {
          m.toolCallsJson = null;
          base64PurgeStats.toolCallsCleared++;
          changed = true;
        }
        if (_looksLikeLooseBase64Chunk(m.content)) {
          m.content = '';
          base64PurgeStats.contentCleared++;
          changed = true;
        }
      }

      if (changed) {
        modified++;
        toUpdate.add(m);
      }
    }

    if (opts.apply && toUpdate.isNotEmpty) {
      for (final message in toUpdate) {
        final ok = await _putMessageWithFallback(
          isar: isar,
          message: message,
          stats: writeStats,
        );
        if (ok) {
          persisted++;
        } else {
          skipped++;
        }
      }
    }

    if (scanned % (opts.batchSize * 5) == 0) {
      stdout.writeln('... scanned=$scanned modified=$modified');
    }
  }

  await isar.close();

  stdout.writeln('');
  stdout.writeln('Done in ${sw.elapsedMilliseconds}ms');
  stdout.writeln('Messages scanned: $scanned');
  stdout.writeln('Messages modified(candidate): $modified');
  if (opts.apply) {
    stdout.writeln('Messages persisted: $persisted');
    stdout.writeln('Messages skipped: $skipped');
  }
  stdout.writeln('');
  stdout.writeln('Images list:');
  stdout.writeln('  count: $totalImagesCountBefore -> $totalImagesCountAfter');
  stdout.writeln(
      '  chars: $totalImagesCharsBefore -> $totalImagesCharsAfter (delta ${totalImagesCharsAfter - totalImagesCharsBefore})');
  stdout.writeln('  dropped empty: ${imageStats.droppedEmpty}');
  stdout.writeln(
      '  dropped invalid data URLs: ${imageStats.droppedInvalidDataUrls}');
  stdout.writeln(
      '  dropped loose base64 chunks: ${imageStats.droppedBase64Chunks}');
  stdout.writeln('  dropped all data URLs: ${imageStats.droppedAllDataUrls}');
  stdout.writeln(
      '  merged chunked data URLs: ${imageStats.mergedChunkedDataUrls}');
  stdout.writeln(
      '  merged prefix duplicates: ${imageStats.mergedPrefixDuplicates}');

  stdout.writeln('');
  stdout.writeln('Attachments list:');
  stdout.writeln(
      '  count: $totalAttachmentsCountBefore -> $totalAttachmentsCountAfter');
  stdout.writeln(
      '  chars: $totalAttachmentsCharsBefore -> $totalAttachmentsCharsAfter (delta ${totalAttachmentsCharsAfter - totalAttachmentsCharsBefore})');
  stdout.writeln('  dropped empty: ${attachmentStats.droppedEmpty}');
  stdout.writeln(
      '  dropped invalid data URLs: ${attachmentStats.droppedInvalidDataUrls}');
  stdout.writeln(
      '  dropped loose base64 chunks: ${attachmentStats.droppedBase64Chunks}');
  stdout.writeln(
      '  dropped all data URLs: ${attachmentStats.droppedAllDataUrls}');
  stdout.writeln(
      '  merged chunked data URLs: ${attachmentStats.mergedChunkedDataUrls}');
  stdout.writeln(
      '  merged prefix duplicates: ${attachmentStats.mergedPrefixDuplicates}');

  if (opts.stripDataUrlsInText) {
    stdout.writeln('');
    stdout.writeln('Text fields (content/reasoning/toolCallsJson):');
    stdout.writeln('  occurrences stripped: ${textStats.occurrences}');
    stdout.writeln('  approx chars removed: ${textStats.removedChars}');
  }

  if (opts.purgeLooseBase64Text) {
    stdout.writeln('');
    stdout.writeln('Loose base64 purge:');
    stdout.writeln('  sessionId cleared: ${base64PurgeStats.sessionIdCleared}');
    stdout.writeln(
        '  assistantId cleared: ${base64PurgeStats.assistantIdCleared}');
    stdout.writeln('  requestId cleared: ${base64PurgeStats.requestIdCleared}');
    stdout.writeln('  model cleared: ${base64PurgeStats.modelCleared}');
    stdout.writeln('  provider cleared: ${base64PurgeStats.providerCleared}');
    stdout.writeln('  role cleared: ${base64PurgeStats.roleCleared}');
    stdout
        .writeln('  toolCallId cleared: ${base64PurgeStats.toolCallIdCleared}');
    stdout.writeln(
        '  reasoningContent cleared: ${base64PurgeStats.reasoningCleared}');
    stdout.writeln(
        '  toolCallsJson cleared: ${base64PurgeStats.toolCallsCleared}');
    stdout.writeln('  content cleared: ${base64PurgeStats.contentCleared}');
  }

  if (opts.apply) {
    stdout.writeln('');
    stdout.writeln('Write fallback stats (Isar 16MB guard):');
    stdout.writeln('  attempted writes: ${writeStats.attempted}');
    stdout.writeln(
        '  fallback drop data attachments: ${writeStats.fallbackDropDataAttachments}');
    stdout.writeln(
        '  fallback drop all attachments: ${writeStats.fallbackDropAllAttachments}');
    stdout.writeln(
        '  fallback drop data images: ${writeStats.fallbackDropDataImages}');
    stdout.writeln(
        '  fallback drop all images: ${writeStats.fallbackDropAllImages}');
    stdout.writeln(
        '  fallback clear meta fields: ${writeStats.fallbackClearMetaFields}');
    stdout.writeln(
        '  fallback clear reasoning: ${writeStats.fallbackClearReasoning}');
    stdout.writeln(
        '  fallback clear toolCallsJson: ${writeStats.fallbackClearToolCalls}');
    stdout.writeln(
        '  fallback clear content: ${writeStats.fallbackClearContent}');
    stdout.writeln('  skipped still-too-large: ${writeStats.skippedTooLarge}');
  }

  if (!opts.apply) {
    stdout.writeln('');
    stdout.writeln('提示: 这次是 dry-run，没有修改数据库。要真正清理请加 --apply');
  }
}

bool _listEquals(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
