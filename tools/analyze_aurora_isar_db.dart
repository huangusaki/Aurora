import 'dart:io';

import 'package:isar_community/isar.dart';
import 'package:path/path.dart' as p;

import 'package:aurora/features/assistant/data/assistant_entity.dart';
import 'package:aurora/features/assistant/data/assistant_memory_item_entity.dart';
import 'package:aurora/features/assistant/data/assistant_memory_job_entity.dart';
import 'package:aurora/features/assistant/data/assistant_memory_state_entity.dart';
import 'package:aurora/features/chat/data/message_entity.dart';
import 'package:aurora/features/chat/data/session_entity.dart';
import 'package:aurora/features/chat/data/topic_entity.dart';
import 'package:aurora/features/knowledge/data/knowledge_entities.dart';
import 'package:aurora/features/settings/data/chat_preset_entity.dart';
import 'package:aurora/features/settings/data/daily_usage_stats_entity.dart';
import 'package:aurora/features/settings/data/provider_config_entity.dart';
import 'package:aurora/features/settings/data/usage_stats_entity.dart';

import 'aurora_isar_tooling.dart';

class _Options {
  const _Options({
    required this.dbDir,
    required this.top,
    required this.batchSize,
    required this.maxMessages,
    required this.deepScan,
  });

  final String? dbDir;
  final int top;
  final int batchSize;
  final int maxMessages; // 0 = unlimited
  final bool deepScan;
}

void _printUsage() {
  stdout.writeln('Aurora Isar 数据库分析脚本（不会输出 base64 内容）');
  stdout.writeln('');
  stdout.writeln('用法:');
  stdout.writeln('  dart run tools/analyze_aurora_isar_db.dart [选项]');
  stdout.writeln('');
  stdout.writeln('示例:');
  stdout.writeln(
      r'  dart run tools/analyze_aurora_isar_db.dart --db-dir "C:\Users\<你>\AppData\Roaming\Aurora"');
  stdout.writeln(
      r'  dart run tools/analyze_aurora_isar_db.dart --top 20 --batch-size 1000');
  stdout.writeln(
      r'  dart run tools/analyze_aurora_isar_db.dart --no-deep   (只看各表大小，速度最快)');
  stdout.writeln('');
  stdout.writeln('选项:');
  stdout.writeln('  --db-dir <目录>     Aurora 数据目录(包含 default.isar)。不填则自动尝试查找。');
  stdout.writeln('  --top <N>           Top 列表显示条数(默认 10)。');
  stdout.writeln('  --batch-size <N>    扫描批大小(默认 500)。');
  stdout.writeln('  --max-messages <N>  深度扫描最多处理多少条消息(默认 0=不限)。');
  stdout.writeln('  --no-deep           跳过深度扫描(只输出集合大小/数量)。');
  stdout.writeln('  -h, --help          显示帮助。');
}

_Options _parseArgs(List<String> args) {
  String? dbDir;
  var top = 10;
  var batchSize = 500;
  var maxMessages = 0;
  var deepScan = true;

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '-h' || a == '--help') {
      _printUsage();
      exit(0);
    } else if (a == '--no-deep') {
      deepScan = false;
    } else if (a.startsWith('--db-dir=')) {
      dbDir = a.substring('--db-dir='.length).trim().replaceAll('"', '');
    } else if (a == '--db-dir') {
      if (i + 1 >= args.length) {
        stderr.writeln('缺少 --db-dir 的参数值');
        exit(2);
      }
      dbDir = args[++i];
    } else if (a.startsWith('--top=')) {
      top = int.tryParse(a.substring('--top='.length)) ?? top;
    } else if (a == '--top') {
      if (i + 1 >= args.length) {
        stderr.writeln('缺少 --top 的参数值');
        exit(2);
      }
      top = int.tryParse(args[++i]) ?? top;
    } else if (a.startsWith('--batch-size=')) {
      batchSize =
          int.tryParse(a.substring('--batch-size='.length).trim()) ?? batchSize;
    } else if (a == '--batch-size') {
      if (i + 1 >= args.length) {
        stderr.writeln('缺少 --batch-size 的参数值');
        exit(2);
      }
      batchSize = int.tryParse(args[++i]) ?? batchSize;
    } else if (a.startsWith('--max-messages=')) {
      maxMessages =
          int.tryParse(a.substring('--max-messages='.length).trim()) ??
              maxMessages;
    } else if (a == '--max-messages') {
      if (i + 1 >= args.length) {
        stderr.writeln('缺少 --max-messages 的参数值');
        exit(2);
      }
      maxMessages = int.tryParse(args[++i]) ?? maxMessages;
    } else {
      stderr.writeln('未知参数: $a');
      stderr.writeln('');
      _printUsage();
      exit(2);
    }
  }

  if (top < 1) top = 10;
  if (top > 100) top = 100;
  if (batchSize <= 0) batchSize = 500;
  if (batchSize > 10000) batchSize = 10000;
  if (maxMessages < 0) maxMessages = 0;

  return _Options(
    dbDir: dbDir,
    top: top,
    batchSize: batchSize,
    maxMessages: maxMessages,
    deepScan: deepScan,
  );
}

String _safeOneLine(String? value, {int maxLen = 80}) {
  if (value == null) return '-';
  final v = value.replaceAll('\r', ' ').replaceAll('\n', ' ').trim();
  if (v.isEmpty) return '-';
  if (v.length <= maxLen) return v;
  return '${v.substring(0, maxLen)}…';
}

String _formatSessionLabel(
    {required String? sessionId, required String? sessionTitle}) {
  final title = sessionTitle?.trim();
  if (title != null && title.isNotEmpty) {
    return _safeOneLine(title, maxLen: 48);
  }
  if (sessionId == null || sessionId.isEmpty) return '-';
  final prefix = _safeOneLine(sessionId, maxLen: 16);
  return '$prefix (len=${sessionId.length})';
}

class _TopMessage {
  _TopMessage({
    required this.id,
    required this.timestamp,
    required this.sessionId,
    required this.sessionTitle,
    required this.isUser,
    required this.imagesCount,
    required this.imagesChars,
    required this.attachmentsCount,
    required this.attachmentsChars,
    required this.metaChars,
    required this.contentLen,
    required this.reasoningLen,
    required this.toolCallsLen,
  });

  final int id;
  final DateTime timestamp;
  final String? sessionId;
  final String? sessionTitle;
  final bool isUser;
  final int imagesCount;
  final int imagesChars;
  final int attachmentsCount;
  final int attachmentsChars;
  final int metaChars;
  final int contentLen;
  final int reasoningLen;
  final int toolCallsLen;

  int get totalChars =>
      imagesChars +
      attachmentsChars +
      metaChars +
      contentLen +
      reasoningLen +
      toolCallsLen;

  int get sessionIdLen => sessionId?.length ?? 0;

  int get totalCharsWithSessionId => totalChars + sessionIdLen;
}

class _TopImage {
  _TopImage({
    required this.messageId,
    required this.timestamp,
    required this.sessionId,
    required this.sessionTitle,
    required this.index,
    required this.length,
    required this.header,
  });

  final int messageId;
  final DateTime timestamp;
  final String? sessionId;
  final String? sessionTitle;
  final int index;
  final int length;
  final String header;
}

void _pushTopN<T>(
  List<T> list,
  T item,
  int top,
  int Function(T a) score,
) {
  list.add(item);
  list.sort((a, b) => score(b).compareTo(score(a)));
  if (list.length > top) {
    list.removeRange(top, list.length);
  }
}

int _sumStringLengths(List<String> xs) =>
    xs.fold<int>(0, (sum, s) => sum + s.length);

bool _looksLikeLooseBase64Chunk(String s) {
  if (s.length < 512) return false;
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

  final isarFile = File(p.join(dbDir, 'default.isar'));
  if (!isarFile.existsSync()) {
    stderr.writeln('未找到数据库文件: ${isarFile.path}');
    exit(2);
  }

  stdout.writeln('DB: $dbDir');
  stdout.writeln('default.isar: ${formatBytes(isarFile.lengthSync())}');
  final lock = File(p.join(dbDir, 'default.isar.lock'));
  if (lock.existsSync()) {
    stdout.writeln('default.isar.lock: exists (Aurora 可能仍在运行)');
  }
  stdout.writeln('');

  await ensureIsarCoreLoaded();

  final isar = await Isar.open(
    auroraIsarSchemas,
    directory: dbDir,
  );

  stdout.writeln('');
  stdout.writeln('**Collections**');
  final collections = <({String name, IsarCollection<dynamic> col})>[
    (name: 'ProviderConfigEntity', col: isar.providerConfigEntitys),
    (name: 'AppSettingsEntity', col: isar.appSettingsEntitys),
    (name: 'MessageEntity', col: isar.messageEntitys),
    (name: 'SessionEntity', col: isar.sessionEntitys),
    (name: 'UsageStatsEntity', col: isar.usageStatsEntitys),
    (name: 'DailyUsageStatsEntity', col: isar.dailyUsageStatsEntitys),
    (name: 'TopicEntity', col: isar.topicEntitys),
    (name: 'ChatPresetEntity', col: isar.chatPresetEntitys),
    (name: 'AssistantEntity', col: isar.assistantEntitys),
    (name: 'AssistantMemoryItemEntity', col: isar.assistantMemoryItemEntitys),
    (name: 'AssistantMemoryStateEntity', col: isar.assistantMemoryStateEntitys),
    (name: 'AssistantMemoryJobEntity', col: isar.assistantMemoryJobEntitys),
    (name: 'KnowledgeBaseEntity', col: isar.knowledgeBaseEntitys),
    (name: 'KnowledgeDocumentEntity', col: isar.knowledgeDocumentEntitys),
    (name: 'KnowledgeChunkEntity', col: isar.knowledgeChunkEntitys),
  ];

  var totalDataBytes = 0;
  var totalWithIndexesBytes = 0;
  for (final c in collections) {
    final count = c.col.countSync();
    final dataSize = c.col.getSizeSync();
    final fullSize = c.col.getSizeSync(includeIndexes: true);
    totalDataBytes += dataSize;
    totalWithIndexesBytes += fullSize;
    stdout.writeln(
      '${c.name.padRight(26)} count=${count.toString().padLeft(7)}  data=${formatBytes(dataSize).padLeft(10)}  +idx=${formatBytes(fullSize).padLeft(10)}',
    );
  }
  stdout.writeln(
    '${'TOTAL'.padRight(26)} '
    'data=${formatBytes(totalDataBytes)}  '
    '+idx=${formatBytes(totalWithIndexesBytes)}',
  );

  if (!opts.deepScan) {
    await isar.close();
    return;
  }

  stdout.writeln('');
  stdout.writeln('**Messages (Deep Scan)**');

  final sessionTitleById = <String, String>{};
  try {
    final sessions = await isar.sessionEntitys.where().findAll();
    for (final s in sessions) {
      sessionTitleById[s.sessionId] = s.title;
    }
  } catch (_) {
    // ignore
  }

  final totalMessages = isar.messageEntitys.countSync();
  final messagesWithImages =
      await isar.messageEntitys.where().filter().imagesIsNotEmpty().count();
  final messagesWithDataImageInContent = await isar.messageEntitys
      .where()
      .filter()
      .contentContains('data:image/', caseSensitive: false)
      .count();
  final messagesWithDataImageInReasoning = await isar.messageEntitys
      .where()
      .filter()
      .reasoningContentContains('data:image/', caseSensitive: false)
      .count();
  final messagesWithDataImageInTools = await isar.messageEntitys
      .where()
      .filter()
      .toolCallsJsonContains('data:image/', caseSensitive: false)
      .count();

  stdout.writeln('Total messages: $totalMessages');
  stdout.writeln('Messages with images[]: $messagesWithImages');
  stdout.writeln(
      'Messages with data:image in content: $messagesWithDataImageInContent');
  stdout.writeln(
      'Messages with data:image in reasoning: $messagesWithDataImageInReasoning');
  stdout.writeln(
      'Messages with data:image in toolCallsJson: $messagesWithDataImageInTools');

  // Scan all messages to find hidden bloat outside images[].
  var allScanned = 0;
  var allLastId = 0;
  var allImagesCount = 0;
  var allImagesChars = 0;
  var allAttachmentsCount = 0;
  var allAttachmentsChars = 0;
  var allDataUrlAttachments = 0;
  var allLooseBase64Attachments = 0;
  var allContentChars = 0;
  var allReasoningChars = 0;
  var allToolCallsChars = 0;
  var allSessionIdChars = 0;
  var allAssistantIdChars = 0;
  var allRequestIdChars = 0;
  var allModelChars = 0;
  var allProviderChars = 0;
  var allRoleChars = 0;
  var allToolCallIdChars = 0;
  var allHugeSessionIdCount = 0;

  final topAllByTotal = <_TopMessage>[];
  final topAllByReasoning = <_TopMessage>[];
  final topAllBySessionId = <_TopMessage>[];
  final topAllByAttachments = <_TopMessage>[];

  while (true) {
    final query = isar.messageEntitys
        .where()
        .idGreaterThan(allLastId)
        .limit(opts.batchSize);
    final batch = await query.findAll();
    if (batch.isEmpty) break;
    allLastId = batch.last.id;

    for (final m in batch) {
      allScanned++;
      if (opts.maxMessages > 0 && allScanned > opts.maxMessages) {
        batch.clear();
        break;
      }

      final imagesChars = _sumStringLengths(m.images);
      final attachmentsChars = _sumStringLengths(m.attachments);
      final assistantIdLen = m.assistantId?.length ?? 0;
      final requestIdLen = m.requestId?.length ?? 0;
      final modelLen = m.model?.length ?? 0;
      final providerLen = m.provider?.length ?? 0;
      final roleLen = m.role?.length ?? 0;
      final toolCallIdLen = m.toolCallId?.length ?? 0;
      final metaChars = assistantIdLen +
          requestIdLen +
          modelLen +
          providerLen +
          roleLen +
          toolCallIdLen;
      final sidLen = m.sessionId?.length ?? 0;
      if (sidLen > 200) {
        allHugeSessionIdCount++;
      }

      allImagesCount += m.images.length;
      allImagesChars += imagesChars;
      allAttachmentsCount += m.attachments.length;
      allAttachmentsChars += attachmentsChars;
      for (final a in m.attachments) {
        final trimmed = a.trim();
        if (trimmed.startsWith('data:')) {
          allDataUrlAttachments++;
        } else if (_looksLikeLooseBase64Chunk(trimmed)) {
          allLooseBase64Attachments++;
        }
      }
      allContentChars += m.content.length;
      allReasoningChars += m.reasoningContent?.length ?? 0;
      allToolCallsChars += m.toolCallsJson?.length ?? 0;
      allSessionIdChars += sidLen;
      allAssistantIdChars += assistantIdLen;
      allRequestIdChars += requestIdLen;
      allModelChars += modelLen;
      allProviderChars += providerLen;
      allRoleChars += roleLen;
      allToolCallIdChars += toolCallIdLen;

      final top = _TopMessage(
        id: m.id,
        timestamp: m.timestamp,
        sessionId: m.sessionId,
        sessionTitle:
            m.sessionId == null ? null : sessionTitleById[m.sessionId!],
        isUser: m.isUser,
        imagesCount: m.images.length,
        imagesChars: imagesChars,
        attachmentsCount: m.attachments.length,
        attachmentsChars: attachmentsChars,
        metaChars: metaChars,
        contentLen: m.content.length,
        reasoningLen: m.reasoningContent?.length ?? 0,
        toolCallsLen: m.toolCallsJson?.length ?? 0,
      );

      _pushTopN(topAllByTotal, top, opts.top, (x) => x.totalCharsWithSessionId);
      _pushTopN(topAllByReasoning, top, opts.top, (x) => x.reasoningLen);
      _pushTopN(topAllBySessionId, top, opts.top, (x) => x.sessionIdLen);
      _pushTopN(topAllByAttachments, top, opts.top, (x) => x.attachmentsChars);
    }

    if (opts.maxMessages > 0 && allScanned > opts.maxMessages) break;
  }

  stdout.writeln('');
  stdout.writeln('All-message chars summary:');
  stdout.writeln('  scanned=$allScanned');
  stdout.writeln(
      '  images: count=$allImagesCount chars=$allImagesChars (~${formatBytes(allImagesChars)})');
  stdout.writeln(
      '  attachments: count=$allAttachmentsCount chars=$allAttachmentsChars (~${formatBytes(allAttachmentsChars)})');
  stdout.writeln(
      '    attachment types: data=$allDataUrlAttachments looseBase64=$allLooseBase64Attachments other=${allAttachmentsCount - allDataUrlAttachments - allLooseBase64Attachments}');
  stdout.writeln('  content chars=$allContentChars');
  stdout.writeln('  reasoning chars=$allReasoningChars');
  stdout.writeln('  toolCallsJson chars=$allToolCallsChars');
  stdout.writeln('  sessionId chars=$allSessionIdChars');
  stdout.writeln(
      '  meta chars(total)=${allAssistantIdChars + allRequestIdChars + allModelChars + allProviderChars + allRoleChars + allToolCallIdChars}');
  stdout.writeln(
      '    assistantId=$allAssistantIdChars requestId=$allRequestIdChars model=$allModelChars provider=$allProviderChars role=$allRoleChars toolCallId=$allToolCallIdChars');
  if (allHugeSessionIdCount > 0) {
    stdout.writeln('  sessionId anomalies(len>200)=$allHugeSessionIdCount');
  }

  if (topAllByTotal.isNotEmpty) {
    stdout.writeln('');
    stdout.writeln('Top messages by total chars (all fields):');
    for (final t in topAllByTotal) {
      final session = _formatSessionLabel(
          sessionId: t.sessionId, sessionTitle: t.sessionTitle);
      stdout.writeln(
        '  id=${t.id} time=${t.timestamp.toIso8601String()} session=$session isUser=${t.isUser} sidLen=${t.sessionIdLen} images=${t.imagesChars} attachments=${t.attachmentsChars} meta=${t.metaChars} content=${t.contentLen} reasoning=${t.reasoningLen} tools=${t.toolCallsLen} total=${t.totalCharsWithSessionId}',
      );
    }
  }

  if (topAllByReasoning.any((t) => t.reasoningLen > 0)) {
    stdout.writeln('');
    stdout.writeln('Top messages by reasoning length (all messages):');
    for (final t in topAllByReasoning.where((x) => x.reasoningLen > 0)) {
      final session = _formatSessionLabel(
          sessionId: t.sessionId, sessionTitle: t.sessionTitle);
      stdout.writeln(
        '  id=${t.id} time=${t.timestamp.toIso8601String()} session=$session reasoning=${t.reasoningLen} total=${t.totalCharsWithSessionId}',
      );
    }
  }

  if (topAllBySessionId.any((t) => t.sessionIdLen > 0)) {
    stdout.writeln('');
    stdout.writeln('Top messages by sessionId length (all messages):');
    for (final t in topAllBySessionId.where((x) => x.sessionIdLen > 0)) {
      final session = _formatSessionLabel(
          sessionId: t.sessionId, sessionTitle: t.sessionTitle);
      stdout.writeln(
        '  id=${t.id} time=${t.timestamp.toIso8601String()} session=$session sidLen=${t.sessionIdLen} total=${t.totalCharsWithSessionId}',
      );
    }
  }

  if (topAllByAttachments.any((t) => t.attachmentsChars > 0)) {
    stdout.writeln('');
    stdout.writeln('Top messages by attachments chars (all messages):');
    for (final t in topAllByAttachments.where((x) => x.attachmentsChars > 0)) {
      final session = _formatSessionLabel(
          sessionId: t.sessionId, sessionTitle: t.sessionTitle);
      stdout.writeln(
        '  id=${t.id} time=${t.timestamp.toIso8601String()} session=$session attachmentsCount=${t.attachmentsCount} attachmentsChars=${t.attachmentsChars} total=${t.totalCharsWithSessionId}',
      );
    }
  }

  // Scan messages with images to find heavy hitters.
  var scanned = 0;
  var lastId = 0;
  var totalImages = 0;
  var totalImagesChars = 0;
  var totalAttachmentsCount = 0;
  var totalAttachmentsChars = 0;
  var totalDataUrlAttachments = 0;
  var totalLooseBase64Attachments = 0;
  var totalContentChars = 0;
  var totalReasoningChars = 0;
  var totalToolCallsChars = 0;
  var totalDataUrlImages = 0;
  var totalNonDataImages = 0;

  final topByImages = <_TopMessage>[];
  final topByTotal = <_TopMessage>[];
  final topImages = <_TopImage>[];
  var hugeSessionIdCount = 0;
  var hugeSessionIdChars = 0;

  while (true) {
    final query = isar.messageEntitys
        .where()
        .idGreaterThan(lastId)
        .filter()
        .imagesIsNotEmpty()
        .limit(opts.batchSize);

    final batch = await query.findAll();
    if (batch.isEmpty) break;
    lastId = batch.last.id;

    for (final m in batch) {
      scanned++;
      if (opts.maxMessages > 0 && scanned > opts.maxMessages) {
        batch.clear();
        break;
      }

      final imagesCount = m.images.length;
      final imagesChars = _sumStringLengths(m.images);
      final attachmentsChars = _sumStringLengths(m.attachments);
      final metaChars = (m.assistantId?.length ?? 0) +
          (m.requestId?.length ?? 0) +
          (m.model?.length ?? 0) +
          (m.provider?.length ?? 0) +
          (m.role?.length ?? 0) +
          (m.toolCallId?.length ?? 0);
      final sidLen = m.sessionId?.length ?? 0;
      if (sidLen > 200) {
        hugeSessionIdCount++;
        hugeSessionIdChars += sidLen;
      }
      totalImages += imagesCount;
      totalImagesChars += imagesChars;
      totalAttachmentsCount += m.attachments.length;
      totalAttachmentsChars += attachmentsChars;
      for (final a in m.attachments) {
        final trimmed = a.trim();
        if (trimmed.startsWith('data:')) {
          totalDataUrlAttachments++;
        } else if (_looksLikeLooseBase64Chunk(trimmed)) {
          totalLooseBase64Attachments++;
        }
      }
      totalContentChars += m.content.length;
      totalReasoningChars += (m.reasoningContent?.length ?? 0);
      totalToolCallsChars += (m.toolCallsJson?.length ?? 0);

      for (var i = 0; i < m.images.length; i++) {
        final url = m.images[i];
        if (url.startsWith('data:')) {
          totalDataUrlImages++;
        } else {
          totalNonDataImages++;
        }

        final commaIndex = url.indexOf(',');
        final header = commaIndex > 0
            ? url.substring(0, commaIndex.clamp(0, 80))
            : url.substring(0, url.length.clamp(0, 80));
        _pushTopN(
          topImages,
          _TopImage(
            messageId: m.id,
            timestamp: m.timestamp,
            sessionId: m.sessionId,
            sessionTitle:
                m.sessionId == null ? null : sessionTitleById[m.sessionId!],
            index: i,
            length: url.length,
            header: header,
          ),
          opts.top,
          (x) => x.length,
        );
      }

      final top = _TopMessage(
        id: m.id,
        timestamp: m.timestamp,
        sessionId: m.sessionId,
        sessionTitle:
            m.sessionId == null ? null : sessionTitleById[m.sessionId!],
        isUser: m.isUser,
        imagesCount: imagesCount,
        imagesChars: imagesChars,
        attachmentsCount: m.attachments.length,
        attachmentsChars: attachmentsChars,
        metaChars: metaChars,
        contentLen: m.content.length,
        reasoningLen: m.reasoningContent?.length ?? 0,
        toolCallsLen: m.toolCallsJson?.length ?? 0,
      );

      _pushTopN(topByImages, top, opts.top, (x) => x.imagesChars);
      _pushTopN(topByTotal, top, opts.top, (x) => x.totalChars);
    }

    if (opts.maxMessages > 0 && scanned > opts.maxMessages) break;
  }

  stdout.writeln('');
  stdout.writeln('Images scan: messages=$scanned images=$totalImages');
  stdout.writeln(
      'Images chars total: $totalImagesChars (~${formatBytes(totalImagesChars)} as UTF-16-ish chars)');
  stdout.writeln(
      'Images types: data: $totalDataUrlImages, non-data: $totalNonDataImages');
  stdout.writeln(
      'Attachments (in messages with images): count=$totalAttachmentsCount chars=$totalAttachmentsChars (~${formatBytes(totalAttachmentsChars)})');
  stdout.writeln(
      '  attachment types: data=$totalDataUrlAttachments looseBase64=$totalLooseBase64Attachments other=${totalAttachmentsCount - totalDataUrlAttachments - totalLooseBase64Attachments}');
  if (hugeSessionIdCount > 0) {
    stdout.writeln(
        'SessionId anomalies (in messages with images): count(sessionIdLen>200)=$hugeSessionIdCount charsTotal=$hugeSessionIdChars');
  }
  stdout.writeln('Message text chars total (for messages with images only):');
  stdout.writeln(
      '  content=$totalContentChars reasoning=$totalReasoningChars toolCallsJson=$totalToolCallsChars');

  if (topByImages.isNotEmpty) {
    stdout.writeln('');
    stdout.writeln('Top messages by images chars:');
    for (final t in topByImages) {
      final session = _formatSessionLabel(
          sessionId: t.sessionId, sessionTitle: t.sessionTitle);
      stdout.writeln(
        '  id=${t.id} time=${t.timestamp.toIso8601String()} session=$session isUser=${t.isUser} images=${t.imagesCount} imagesChars=${t.imagesChars} attachmentsChars=${t.attachmentsChars} meta=${t.metaChars} totalChars=${t.totalChars}',
      );
    }
  }

  if (topByTotal.isNotEmpty) {
    stdout.writeln('');
    stdout.writeln('Top messages by total chars (images+text+tools):');
    for (final t in topByTotal) {
      final session = _formatSessionLabel(
          sessionId: t.sessionId, sessionTitle: t.sessionTitle);
      stdout.writeln(
        '  id=${t.id} time=${t.timestamp.toIso8601String()} session=$session isUser=${t.isUser} imagesChars=${t.imagesChars} attachmentsChars=${t.attachmentsChars} meta=${t.metaChars} content=${t.contentLen} reasoning=${t.reasoningLen} tools=${t.toolCallsLen} total=${t.totalChars}',
      );
    }
  }

  if (topImages.isNotEmpty) {
    stdout.writeln('');
    stdout.writeln('Top images by URL length:');
    for (final t in topImages) {
      final session = _formatSessionLabel(
          sessionId: t.sessionId, sessionTitle: t.sessionTitle);
      final header = _safeOneLine(t.header, maxLen: 80);
      stdout.writeln(
        '  msg=${t.messageId} idx=${t.index} len=${t.length} time=${t.timestamp.toIso8601String()} session=$session header="$header"',
      );
    }
  }

  await isar.close();
}
