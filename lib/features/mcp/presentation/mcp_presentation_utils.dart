import 'dart:convert';

import 'package:aurora/l10n/app_localizations.dart';

import '../domain/mcp_server_config.dart';
import 'mcp_connection_provider.dart';

String mcpStatusLabel(AppLocalizations l10n, McpConnectionStatus status) {
  switch (status) {
    case McpConnectionStatus.ready:
      return l10n.mcpStatusConnected;
    case McpConnectionStatus.connecting:
      return l10n.mcpStatusConnecting;
    case McpConnectionStatus.error:
      return l10n.error;
    case McpConnectionStatus.disconnected:
      return l10n.mcpStatusDisconnected;
  }
}

String summarizeMcpServer(McpServerConfig server) {
  return server.transport == McpServerTransport.http
      ? server.url.trim()
      : [
          server.command,
          ...server.args,
        ].where((value) => value.trim().isNotEmpty).join(' ');
}

Map<String, String> parseMcpKeyValueLines(String raw) {
  final result = <String, String>{};
  for (final line in const LineSplitter().convert(raw)) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      continue;
    }
    final idx = trimmed.indexOf('=');
    if (idx <= 0) {
      continue;
    }
    final key = trimmed.substring(0, idx).trim();
    if (key.isEmpty) {
      continue;
    }
    result[key] = trimmed.substring(idx + 1).trim();
  }
  return result;
}

String encodeMcpKeyValueLines(Map<String, String> pairs) {
  return pairs.entries.map((entry) => '${entry.key}=${entry.value}').join('\n');
}

String encodeMcpArgs(List<String> args) {
  return args.join('\n');
}

List<String> parseMcpLineList(String raw) {
  return const LineSplitter()
      .convert(raw)
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
}

String formatMcpConnectionTestContent(
  AppLocalizations l10n,
  McpConnectionTestResult result,
) {
  final toolNames = result.tools
      .map((tool) => tool.name)
      .where((name) => name.isNotEmpty)
      .toList()
    ..sort();
  final stderr = result.stderrTail.join('\n').trim();

  if (result.success) {
    final toolsText = toolNames.isEmpty ? l10n.none : toolNames.join('\n');
    final stderrText =
        stderr.isNotEmpty ? '\n\n${l10n.mcpStderrTail}\n$stderr' : '';
    return '${l10n.mcpToolsCount}: ${toolNames.length}\n\n$toolsText$stderrText';
  }

  final error = result.error ?? l10n.unknown;
  final stderrText =
      stderr.isNotEmpty ? '\n\n${l10n.mcpStderrTail}\n$stderr' : '';
  return '${l10n.error}: $error$stderrText';
}
