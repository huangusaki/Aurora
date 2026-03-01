import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:aurora/features/mcp/domain/mcp_server_config.dart';
import 'package:aurora/features/mcp/presentation/mcp_connection_provider.dart';
import 'package:aurora/shared/services/tool_manager.dart';
import 'package:aurora/shared/utils/platform_utils.dart';

String _resolveDartExecutable() {
  final exe = Platform.resolvedExecutable;
  final lower = exe.toLowerCase();
  if (lower.endsWith('dart') || lower.endsWith('dart.exe')) return exe;
  return 'dart';
}

void main() {
  test('ToolManager: MCP tools injected and callable', () async {
    final scriptPath = [
      Directory.current.path,
      'test',
      'shared',
      'services',
      'mcp',
      'fake_mcp_server.dart',
    ].join(Platform.pathSeparator);

    final server = McpServerConfig(
      id: 'test-mcp-server',
      name: 'Fake MCP',
      enabled: true,
      transport: McpServerTransport.stdio,
      command: _resolveDartExecutable(),
      args: [scriptPath],
      runInShell: PlatformUtils.isWindows,
    );

    final mcpConnection = McpConnectionNotifier();
    final manager = ToolManager(mcpConnection: mcpConnection);
    addTearDown(() async {
      await mcpConnection.disconnect(server.id);
      mcpConnection.dispose();
    });

    final tools = await manager.getTools(mcpServers: [server]);
    final names = tools
        .map((t) => (t['function'] as Map?)?['name']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();

    expect(
      names.any((n) => n.startsWith('mcp__${server.id}__')),
      isTrue,
    );

    final toolName = names.firstWhere((n) => n.startsWith('mcp__${server.id}__'));
    final raw = await manager.executeTool(toolName, {'text': 'hello'}, mcpServers: [server]);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    expect(decoded['isError'], isFalse);
    final content = decoded['content'] as List;
    expect((content.first as Map)['text'], 'hello');

    // Give background session close a moment to terminate the fake server.
    await Future.delayed(const Duration(milliseconds: 200));
  }, timeout: const Timeout(Duration(seconds: 20)));
}
