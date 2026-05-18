import 'dart:ffi' show Abi;
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

final List<CollectionSchema<dynamic>> auroraIsarSchemas = [
  ProviderConfigEntitySchema,
  AppSettingsEntitySchema,
  MessageEntitySchema,
  SessionEntitySchema,
  UsageStatsEntitySchema,
  DailyUsageStatsEntitySchema,
  TopicEntitySchema,
  ChatPresetEntitySchema,
  AssistantEntitySchema,
  AssistantMemoryItemEntitySchema,
  AssistantMemoryStateEntitySchema,
  AssistantMemoryJobEntitySchema,
  KnowledgeBaseEntitySchema,
  KnowledgeDocumentEntitySchema,
  KnowledgeChunkEntitySchema,
];

String formatBytes(int bytes) {
  const kb = 1024;
  const mb = 1024 * 1024;
  const gb = 1024 * 1024 * 1024;
  if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(2)} GB';
  if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(2)} MB';
  if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(2)} KB';
  return '$bytes B';
}

String? autoDetectAuroraDbDir() {
  final candidates = <String>[];

  void scanBaseDir(String? baseDir) {
    if (baseDir == null || baseDir.trim().isEmpty) return;
    final base = Directory(baseDir);
    if (!base.existsSync()) return;
    try {
      for (final entity in base.listSync(followLinks: false)) {
        if (entity is! Directory) continue;
        final isarFile = File(p.join(entity.path, 'default.isar'));
        if (isarFile.existsSync()) {
          candidates.add(entity.path);
        }
      }
    } catch (_) {
      // Ignore permission errors from broad user-data scans.
    }
  }

  if (Platform.isWindows) {
    scanBaseDir(Platform.environment['APPDATA']);
    scanBaseDir(Platform.environment['LOCALAPPDATA']);
  } else if (Platform.isMacOS) {
    final home = Platform.environment['HOME'];
    if (home != null) {
      scanBaseDir(p.join(home, 'Library', 'Application Support'));
    }
  } else if (Platform.isLinux) {
    final home = Platform.environment['HOME'];
    if (home != null) {
      scanBaseDir(p.join(home, '.local', 'share'));
    }
  }

  if (candidates.length == 1) return candidates.single;
  if (candidates.isEmpty) return null;

  stderr.writeln('检测到多个包含 default.isar 的目录，请用 --db-dir 指定其中一个:');
  for (final c in candidates) {
    stderr.writeln('  - $c');
  }
  return null;
}

Future<void> ensureIsarCoreLoaded() async {
  if (Platform.isAndroid || Platform.isIOS) return;

  final fileName = _platformIsarCoreFileName();
  final scriptDir = p.dirname(Platform.script.toFilePath());
  final localCandidate = fileName == null ? null : p.join(scriptDir, fileName);
  final pubCacheCandidate = _findIsarCoreLibraryInPubCache();

  final candidates = <String>[
    if (localCandidate != null) localCandidate,
    if (fileName != null) fileName,
    if (pubCacheCandidate != null) pubCacheCandidate,
  ];

  Object? lastError;
  for (final lib in candidates) {
    try {
      final looksLikePath = lib.contains('/') ||
          lib.contains('\\') ||
          (Platform.isWindows && lib.contains(':'));
      if (looksLikePath && !File(lib).existsSync()) continue;
      await Isar.initializeIsarCore(
        libraries: {Abi.current(): lib},
        download: false,
      );
      stdout.writeln('IsarCore: $lib');
      return;
    } catch (error) {
      lastError = error;
    }
  }

  try {
    stdout.writeln('IsarCore: downloading to script dir...');
    await Isar.initializeIsarCore(download: true);
    return;
  } catch (error) {
    lastError ??= error;
  }

  throw StateError('IsarCore 初始化失败: $lastError');
}

String? _platformIsarCoreSubdir() {
  if (Platform.isWindows) return 'windows';
  if (Platform.isMacOS) return 'macos';
  if (Platform.isLinux) return 'linux';
  return null;
}

String? _platformIsarCoreFileName() {
  if (Platform.isWindows) return 'libisar.dll';
  if (Platform.isMacOS) return 'libisar.dylib';
  if (Platform.isLinux) return 'libisar.so';
  return null;
}

String? _defaultPubCacheDir() {
  final env = Platform.environment;
  final explicit = env['PUB_CACHE'];
  if (explicit != null && explicit.trim().isNotEmpty) return explicit.trim();
  if (Platform.isWindows) {
    final localAppData = env['LOCALAPPDATA'];
    if (localAppData == null || localAppData.trim().isEmpty) return null;
    return p.join(localAppData.trim(), 'Pub', 'Cache');
  }
  final home = env['HOME'];
  if (home == null || home.trim().isEmpty) return null;
  return p.join(home.trim(), '.pub-cache');
}

String? _findIsarCoreLibraryInPubCache() {
  final platformSubdir = _platformIsarCoreSubdir();
  final fileName = _platformIsarCoreFileName();
  if (platformSubdir == null || fileName == null) return null;

  final pubCache = _defaultPubCacheDir();
  if (pubCache == null) return null;

  final hostedDir = Directory(p.join(pubCache, 'hosted'));
  if (!hostedDir.existsSync()) return null;

  final expectedPackageDir = 'isar_community_flutter_libs-${Isar.version}';

  for (final entity in hostedDir.listSync(followLinks: false)) {
    if (entity is! Directory) continue;
    final candidate = File(
      p.join(entity.path, expectedPackageDir, platformSubdir, fileName),
    );
    if (candidate.existsSync()) return candidate.path;
  }

  try {
    for (final entity in hostedDir.listSync(followLinks: false)) {
      if (entity is! Directory) continue;
      for (final pkg in entity.listSync(followLinks: false)) {
        if (pkg is! Directory) continue;
        final name = p.basename(pkg.path);
        if (!name.startsWith('isar_community_flutter_libs-')) continue;
        final candidate = File(p.join(pkg.path, platformSubdir, fileName));
        if (candidate.existsSync()) return candidate.path;
      }
    }
  } catch (_) {
    // Ignore transient directory walk errors in pub cache.
  }

  return null;
}
