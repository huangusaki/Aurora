import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:aurora/shared/services/mcp/mcp_client_session.dart';
import 'package:aurora/shared/utils/platform_utils.dart';

String _resolveDartExecutable() {
  final exe = Platform.resolvedExecutable;
  final lower = exe.toLowerCase();
  if (lower.endsWith('dart') || lower.endsWith('dart.exe')) return exe;
  return 'dart';
}

void main() {
  test('MCP stdio: initialize + tools/list + tools/call', () async {
    final scriptPath = [
      Directory.current.path,
      'test',
      'shared',
      'services',
      'mcp',
      'fake_mcp_server.dart',
    ].join(Platform.pathSeparator);

    final session = await McpClientSession.connect(
      command: _resolveDartExecutable(),
      args: [scriptPath],
      runInShell: PlatformUtils.isWindows,
    );
    addTearDown(() async {
      await session.close();
    });

    await session.initialize();

    final tools = await session.listToolsAll();
    expect(tools.map((t) => t.name), contains('echo'));

    final result = await session.callTool('echo', {'text': 'hello'});
    expect(result['isError'], isFalse);
    final content = result['content'];
    expect(content, isA<List>());
    final first = (content as List).first as Map;
    expect(first['type'], 'text');
    expect(first['text'], 'hello');
  }, timeout: const Timeout(Duration(seconds: 20)));
}
