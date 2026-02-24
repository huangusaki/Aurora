import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/mcp_server_config.dart';

class McpServerStorage {
  static const int currentVersion = 1;

  Future<File> get _configFile async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'mcp_servers.json'));
  }

  Future<List<McpServerConfig>> loadServers() async {
    try {
      final file = await _configFile;
      if (!await file.exists()) return const [];

      final content = await file.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is! Map) return const [];

      final map = decoded.map((k, v) => MapEntry('$k', v));
      final rawServers = map['servers'];
      if (rawServers is! List) return const [];

      final servers = <McpServerConfig>[];
      for (final item in rawServers) {
        if (item is Map) {
          final cfg = McpServerConfig.fromJson(
              item.map((k, v) => MapEntry('$k', v)));
          if (cfg.id.trim().isNotEmpty && cfg.command.trim().isNotEmpty) {
            servers.add(cfg);
          }
        }
      }
      return servers;
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveServers(List<McpServerConfig> servers) async {
    final data = {
      'version': currentVersion,
      'servers': servers.map((s) => s.toJson()).toList(),
    };
    final payload = const JsonEncoder.withIndent('  ').convert(data);

    final file = await _configFile;
    final dir = file.parent;
    try {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    } catch (_) {}

    final tmpPath = p.join(dir.path, 'mcp_servers.json.tmp');
    final tmp = File(tmpPath);

    try {
      await tmp.writeAsString(payload);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
      await tmp.rename(file.path);
    } catch (_) {
      // Fallback: best-effort direct write.
      try {
        await file.writeAsString(payload);
      } catch (_) {}
      try {
        if (await tmp.exists()) await tmp.delete();
      } catch (_) {}
    }
  }
}

