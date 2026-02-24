import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:aurora_search/aurora_search.dart';
import '../../features/mcp/domain/mcp_server_config.dart';
import '../../features/skills/domain/skill_entity.dart';
import 'package:aurora/shared/utils/platform_utils.dart';
import 'mcp/mcp_client_session.dart';

class _McpToolBinding {
  final String serverId;
  final String toolName;

  const _McpToolBinding({required this.serverId, required this.toolName});
}

class ToolManager {
  ToolManager({
    this.searchRegion = 'us-en',
    this.searchSafeSearch = 'moderate',
    int searchMaxResults = 5,
    this.searchTimeout = const Duration(seconds: 15),
  })  : searchMaxResults = searchMaxResults.clamp(1, 50),
        _search = AuroraSearch(timeout: searchTimeout);

  final String searchRegion;
  final String searchSafeSearch;
  final int searchMaxResults;
  final Duration searchTimeout;

  final AuroraSearch _search;
  final Dio _dio =
      Dio(BaseOptions(connectTimeout: const Duration(seconds: 10)));

  final Map<String, _McpToolBinding> _mcpToolBindings = {};
  final Map<String, McpClientSession> _mcpSessions = {};

  Future<List<Map<String, dynamic>>> getTools({
    List<Skill> skills = const [],
    List<McpServerConfig> mcpServers = const [],
  }) async {
    final tools = <Map<String, dynamic>>[];

    _resetMcpState();

    for (final skill in skills) {
      if (!skill.isEnabled || !skill.forAI) continue;
      if (!skill.isCompatible(Platform.operatingSystem)) continue;
      for (final skillTool in skill.tools) {
        var description = skillTool.description;
        if (skillTool.inputExamples.isNotEmpty) {
          final examplesStr =
              skillTool.inputExamples.map((e) => jsonEncode(e)).join(', ');
          description += '\nExamples: $examplesStr';
        }

        tools.add({
          'type': 'function',
          'function': {
            'name': '${skill.id}_${skillTool.name}',
            'description': description,
            'parameters': skillTool.inputSchema,
          },
        });
      }
    }

    final enabledMcpServers = mcpServers.where((s) => s.enabled).toList();
    if (enabledMcpServers.isNotEmpty) {
      final Set<String> openAiToolNames = {};

      await Future.wait(enabledMcpServers.map((server) async {
        McpClientSession? session;
        try {
          session = await McpClientSession.connect(
            command: server.command,
            args: server.args,
            cwd: server.cwd,
            env: server.env.isEmpty ? null : server.env,
            runInShell: server.runInShell,
          );
          const timeout = Duration(seconds: 60);
          await session.initialize(timeout: timeout);
          final mcpTools = await session.listToolsAll(timeout: timeout);
          _mcpSessions[server.id] = session;

          for (final mcpTool in mcpTools) {
            final sanitized = _sanitizeToolName(mcpTool.name);
            final openAiName = _buildOpenAiToolName(
              serverId: server.id,
              toolName: sanitized.isEmpty ? 'tool' : sanitized,
              taken: openAiToolNames,
            );
            _mcpToolBindings[openAiName] = _McpToolBinding(
              serverId: server.id,
              toolName: mcpTool.name,
            );
            tools.add({
              'type': 'function',
              'function': {
                'name': openAiName,
                'description': (mcpTool.description.isNotEmpty
                    ? mcpTool.description
                    : mcpTool.name),
                'parameters': mcpTool.inputSchema,
              },
            });
          }
        } catch (_) {
          try {
            await session?.close();
          } catch (_) {}
        }
      }));
    }

    return tools;
  }

  Future<String> executeTool(String name, Map<String, dynamic> args,
      {String preferredEngine = 'duckduckgo',
      List<Skill> skills = const [],
      List<McpServerConfig> mcpServers = const []}) async {
    if (name == 'SearchWeb') {
      return await _searchWeb(args['query'] ?? '', preferredEngine);
    }

    final binding = _mcpToolBindings[name];
    if (binding != null) {
      try {
        final session =
            await _getOrCreateMcpSession(binding.serverId, mcpServers);
        if (session == null) {
          return jsonEncode({
            'error': 'MCP session not available',
            'serverId': binding.serverId,
            'tool': binding.toolName,
          });
        }
        final result = await session.callTool(binding.toolName, args);
        return jsonEncode(result);
      } catch (e) {
        return jsonEncode({
          'error': 'MCP tool execution failed: $e',
          'serverId': binding.serverId,
          'tool': binding.toolName,
        });
      }
    }

    // Check if it's a skill tool
    for (final skill in skills) {
      for (final tool in skill.tools) {
        if ('${skill.id}_${tool.name}' == name) {
          return await _executeSkillTool(tool, args);
        }
      }
    }

    return jsonEncode({'error': 'Unknown tool: $name'});
  }

  void _resetMcpState() {
    _mcpToolBindings.clear();
    for (final session in _mcpSessions.values) {
      unawaited(session.close());
    }
    _mcpSessions.clear();
  }

  String _sanitizeToolName(String name) {
    final sanitized = name.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return sanitized.isEmpty ? 'tool' : sanitized;
  }

  String _buildOpenAiToolName({
    required String serverId,
    required String toolName,
    required Set<String> taken,
  }) {
    const prefix = 'mcp__';
    const sep = '__';
    final prefixPart = '$prefix$serverId$sep';
    var base = toolName;

    var n = 0;
    while (true) {
      final suffix = n == 0 ? '' : '_${n + 1}';
      final maxToolLen = 64 - prefixPart.length - suffix.length;
      final end = maxToolLen <= 0
          ? 0
          : (base.length > maxToolLen ? maxToolLen : base.length);
      final truncated = base.substring(0, end);
      final candidate = '$prefixPart$truncated$suffix';
      if (!taken.contains(candidate)) {
        taken.add(candidate);
        return candidate;
      }
      n++;
    }
  }

  Future<McpClientSession?> _getOrCreateMcpSession(
    String serverId,
    List<McpServerConfig> servers,
  ) async {
    final existing = _mcpSessions[serverId];
    if (existing != null) return existing;

    McpServerConfig? cfg;
    for (final s in servers) {
      if (s.id == serverId) {
        cfg = s;
        break;
      }
    }
    if (cfg == null) return null;

    try {
      final session = await McpClientSession.connect(
        command: cfg.command,
        args: cfg.args,
        cwd: cfg.cwd,
        env: cfg.env.isEmpty ? null : cfg.env,
        runInShell: cfg.runInShell,
      );
      await session.initialize(timeout: const Duration(seconds: 60));
      _mcpSessions[serverId] = session;
      return session;
    } catch (_) {
      return null;
    }
  }

  Future<String> _executeSkillTool(
      SkillTool tool, Map<String, dynamic> args) async {
    if (tool.type == 'shell') {
      if (PlatformUtils.isMobile) {
        return jsonEncode({
          'error':
              'Shell tools are not supported on mobile platforms. Please use http tools for cross-platform support.',
        });
      }
      try {
        var command = tool.command;
        // Replace parameters in the entire command string
        args.forEach((key, value) {
          var valStr = value.toString();
          if (PlatformUtils.isWindows) {
            // Fix over-escaped backslashes from LLM (D:\\dev -> D:\dev)
            if (valStr.contains(r'\\') && !valStr.startsWith(r'\\')) {
              valStr = valStr.replaceAll(r'\\', r'\');
            }
            // If the command is a PowerShell command using '{{path}}',
            // we must escape single quotes in the value to avoid syntax errors.
            if (tool.command.contains("'{{$key}}'")) {
              valStr = valStr.replaceAll("'", "''");
            }
          }
          command = command.replaceAll('{{$key}}', valStr);
        });

        // Check if any placeholders remain unreplaced
        final regex = RegExp(r'\{\{(.*?)\}\}');
        final remainingMatches = regex.allMatches(command);
        if (remainingMatches.isNotEmpty) {
          final missingKeys = remainingMatches
              .map((m) => m.group(1))
              .where((k) => k != null)
              .cast<String>()
              .toSet();

          return jsonEncode({
            'error':
                'Template execution failed: Some placeholders were not provided.',
            'missing_parameters': missingKeys.toList(),
            'received_args': args,
            'final_command_with_placeholders': command,
          });
        }

        ProcessResult result;
        if (PlatformUtils.isWindows) {
          // Use powershell.exe for all shell tools on Windows.
          // It's much more robust than cmd.exe for complex commands, pipes, and quoting.
          result = await Process.run(
              'powershell.exe', ['-NoProfile', '-Command', command]);
        } else {
          result = await Process.run(command, [], runInShell: true);
        }

        return jsonEncode({
          'stdout': result.stdout.toString(),
          'stderr': result.stderr.toString(),
          'exitCode': result.exitCode,
          'debug_command': command,
        });
      } catch (e) {
        return jsonEncode({
          'error': 'Failed to execute shell tool: $e',
          'command': tool.command,
        });
      }
    } else if (tool.type == 'http' || tool.type == 'api') {
      try {
        var url = tool.command;
        final method =
            (tool.extra['method']?.toString() ?? 'GET').toUpperCase();
        final Map<String, dynamic> queryParams = {};
        final Map<String, dynamic> bodyData = {};

        // Replace placeholders in URL and determine what goes into queryParams/body
        args.forEach((key, value) {
          final placeholder = '{{$key}}';
          final rawValue = value.toString();
          if (url.contains(placeholder)) {
            url = url.replaceAll(placeholder, Uri.encodeComponent(rawValue));
          } else {
            if (method == 'GET') {
              queryParams[key] = value;
            } else {
              bodyData[key] = value;
            }
          }
        });

        Response response;
        final options = Options(
          method: method,
          validateStatus: (status) => status != null && status < 505,
        );

        if (method == 'GET') {
          response = await _dio.get(url,
              queryParameters: queryParams, options: options);
        } else {
          response = await _dio.post(url,
              data: bodyData, queryParameters: queryParams, options: options);
        }

        return jsonEncode({
          'status': response.statusCode,
          'data': response.data,
          'url': url,
        });
      } catch (e) {
        // Redact appid from error logs for privacy if present in local url variable
        return jsonEncode({
          'error': 'HTTP Tool Error: $e',
        });
      }
    }
    return jsonEncode({'error': 'Unsupported tool type: ${tool.type}'});
  }

  Future<String> _searchWeb(String query, String preferredEngine) async {
    final region = searchRegion;
    final safeSearch = searchSafeSearch;
    final enginesToTry = {
      preferredEngine,
      'duckduckgo',
      'bing',
      'google',
    }.toList();
    List<Map<String, dynamic>> finalResults = [];
    String successfulEngine = '';
    List<String> errors = [];
    for (final engine in enginesToTry) {
      if (finalResults.isNotEmpty) break;
      try {
        final results = await _search
            .text(
              query,
              region: region,
              safesearch: safeSearch,
              backend: engine,
              maxResults: searchMaxResults,
            )
            .timeout(searchTimeout);
        if (results.isNotEmpty) {
          finalResults = results;
          successfulEngine = engine;
        }
      } catch (e) {
        errors.add('$engine: $e');
      }
    }
    if (finalResults.isEmpty) {
      return jsonEncode({
        'status': 'error',
        'message':
            'No results found after trying mechanisms: ${enginesToTry.join(', ')}. Errors: ${errors.join('; ')}'
      });
    }
    final formattedResults = finalResults.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final r = entry.value;
      return {
        'index': index,
        'title': r['title'],
        'link': r['href'],
        'snippet': r['body'],
      };
    }).toList();
    return jsonEncode({
      'status': 'success',
      'engine': successfulEngine,
      'results': formattedResults
    });
  }

  void close() {
    _resetMcpState();
    _search.close();
    _dio.close(force: true);
  }
}
