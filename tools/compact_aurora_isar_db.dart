import 'dart:io';

import 'package:isar_community/isar.dart';
import 'package:path/path.dart' as p;

import 'aurora_isar_tooling.dart';

class _Options {
  const _Options({
    required this.dbDir,
    required this.apply,
    required this.force,
    required this.keepBackup,
  });

  final String? dbDir;
  final bool apply;
  final bool force;
  final bool keepBackup;
}

void _printUsage() {
  stdout.writeln('Aurora Isar 压实脚本（回收删除后的空洞页）');
  stdout.writeln('');
  stdout.writeln('用法:');
  stdout.writeln('  dart run tools/compact_aurora_isar_db.dart [选项]');
  stdout.writeln('');
  stdout.writeln('示例:');
  stdout.writeln(
      r'  dart run tools/compact_aurora_isar_db.dart --db-dir "C:\Users\<你>\AppData\Roaming\Aurora"');
  stdout.writeln(
      r'  dart run tools/compact_aurora_isar_db.dart --apply --db-dir "C:\Users\<你>\AppData\Roaming\Aurora"');
  stdout.writeln('');
  stdout.writeln('选项:');
  stdout.writeln('  --db-dir <目录>    Aurora 数据目录(包含 default.isar)。');
  stdout.writeln('  --apply            实际执行压实并替换 default.isar。');
  stdout.writeln('  --force            即使检测到 lock 文件也尝试执行（不推荐）。');
  stdout.writeln('  --no-backup        替换前不保留 default.isar.bak.<时间戳>。');
  stdout.writeln('  -h, --help         显示帮助。');
}

_Options _parseArgs(List<String> args) {
  String? dbDir;
  var apply = false;
  var force = false;
  var keepBackup = true;

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '-h' || a == '--help') {
      _printUsage();
      exit(0);
    } else if (a == '--apply') {
      apply = true;
    } else if (a == '--force') {
      force = true;
    } else if (a == '--no-backup') {
      keepBackup = false;
    } else if (a.startsWith('--db-dir=')) {
      dbDir = a.substring('--db-dir='.length).trim().replaceAll('"', '');
    } else if (a == '--db-dir') {
      if (i + 1 >= args.length) {
        stderr.writeln('缺少 --db-dir 的参数值');
        exit(2);
      }
      dbDir = args[++i];
    } else {
      stderr.writeln('未知参数: $a');
      stderr.writeln('');
      _printUsage();
      exit(2);
    }
  }

  return _Options(
    dbDir: dbDir,
    apply: apply,
    force: force,
    keepBackup: keepBackup,
  );
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

  final dbFile = File(p.join(dbDir, 'default.isar'));
  if (!dbFile.existsSync()) {
    stderr.writeln('未找到数据库文件: ${dbFile.path}');
    exit(2);
  }

  final lockFile = File(p.join(dbDir, 'default.isar.lock'));
  final hasLock = lockFile.existsSync();
  if (hasLock && opts.apply && !opts.force) {
    stderr.writeln('检测到 ${lockFile.path}。Aurora 可能仍在运行。');
    stderr.writeln('请先完全关闭 Aurora 后重试；如确认可忽略，添加 --force。');
    exit(2);
  }

  final beforeBytes = dbFile.lengthSync();

  stdout.writeln('DB: $dbDir');
  stdout.writeln('default.isar: ${formatBytes(beforeBytes)}');
  if (hasLock) {
    stdout.writeln('default.isar.lock: exists');
  }
  stdout.writeln('Mode: ${opts.apply ? 'APPLY(写入替换)' : 'DRY-RUN(仅检查)'}');
  stdout.writeln('');

  if (!opts.apply) {
    stdout.writeln('提示: 该脚本会通过 Isar.copyToFile() 生成压实副本并替换原库。');
    stdout.writeln('执行命令:');
    stdout.writeln(
        '  dart run tools/compact_aurora_isar_db.dart --apply --db-dir "$dbDir"');
    return;
  }

  await ensureIsarCoreLoaded();

  final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
  final compactPath = p.join(dbDir, 'default.compacted.$ts.isar');
  final compactFile = File(compactPath);
  if (compactFile.existsSync()) {
    compactFile.deleteSync();
  }

  Isar? isar;
  try {
    isar = await Isar.open(
      auroraIsarSchemas,
      directory: dbDir,
    );

    stdout.writeln('Creating compacted copy...');
    await isar.copyToFile(compactPath);
  } finally {
    await isar?.close();
  }

  if (!compactFile.existsSync()) {
    stderr.writeln('压实失败：未生成 $compactPath');
    exit(1);
  }

  final compactBytes = compactFile.lengthSync();
  final backupPath = p.join(dbDir, 'default.isar.bak.$ts');
  try {
    if (opts.keepBackup) {
      await dbFile.rename(backupPath);
    } else {
      await dbFile.delete();
    }
    await compactFile.rename(dbFile.path);
  } on PathAccessException catch (e) {
    stderr.writeln('替换 default.isar 失败（文件可能仍被 Aurora 占用）: $e');
    stderr.writeln('已生成压实库: $compactPath (${formatBytes(compactBytes)})');
    stderr.writeln('请关闭 Aurora 后，再把该文件替换为 default.isar。');
    exit(3);
  }

  final afterBytes = dbFile.lengthSync();
  final saved = beforeBytes - afterBytes;

  stdout.writeln('');
  stdout.writeln('Done.');
  stdout.writeln('Before: ${formatBytes(beforeBytes)}');
  stdout.writeln('After : ${formatBytes(afterBytes)}');
  stdout.writeln(
      'Saved : ${saved >= 0 ? formatBytes(saved) : '-${formatBytes(-saved)}'}');
  if (opts.keepBackup) {
    stdout.writeln('Backup: $backupPath');
  }
}
