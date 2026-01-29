import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:ddgs/ddgs.dart';
import '../../features/skills/domain/skill_entity.dart';
import 'package:aurora/shared/utils/platform_utils.dart';

class ToolManager {
  final DDGS _ddgs = DDGS(timeout: const Duration(seconds: 15));
  final Dio _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 10)));
  
  List<Map<String, dynamic>> getTools({List<Skill> skills = const []}) {
    final tools = <Map<String, dynamic>>[
      {
        'type': 'function',
        'function': {
          'name': 'SearchWeb',
          'description':
              'Search the web for current information. Use this when the user asks about up-to-date events, news, or specific knowledge that might be recent.',
          'parameters': {
            'type': 'object',
            'required': ['query'],
            'properties': {
              'query': {
                'type': 'string',
                'description': 'The search query',
              },
            },
          },
        },
      },
    ];

    for (final skill in skills) {
      if (!skill.isEnabled || !skill.forAI) continue;
      if (!skill.isCompatible(Platform.operatingSystem)) continue;
      for (final skillTool in skill.tools) {
        var description = skillTool.description;
        if (skillTool.inputExamples.isNotEmpty) {
          final examplesStr = skillTool.inputExamples.map((e) => jsonEncode(e)).join(', ');
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

    return tools;
  }

  Future<String> executeTool(String name, Map<String, dynamic> args,
      {String preferredEngine = 'duckduckgo', List<Skill> skills = const []}) async {
    if (name == 'SearchWeb') {
      return await _searchWeb(args['query'] ?? '', preferredEngine);
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

  Future<String> _executeSkillTool(SkillTool tool, Map<String, dynamic> args) async {
    if (tool.type == 'shell') {
      if (PlatformUtils.isMobile) {
        return jsonEncode({
          'error': 'Shell tools are not supported on mobile platforms. Please use http tools for cross-platform support.',
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
            'error': 'Template execution failed: Some placeholders were not provided.',
            'missing_parameters': missingKeys.toList(),
            'received_args': args,
            'final_command_with_placeholders': command,
          });
        }

        ProcessResult result;
        if (PlatformUtils.isWindows) {
          // Use powershell.exe for all shell tools on Windows.
          // It's much more robust than cmd.exe for complex commands, pipes, and quoting.
          result = await Process.run('powershell.exe', ['-NoProfile', '-Command', command]);
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
        final method = (tool.extra['method']?.toString() ?? 'GET').toUpperCase();
        final Map<String, dynamic> queryParams = {};
        final Map<String, dynamic> bodyData = {};

        // Replace placeholders in URL and determine what goes into queryParams/body
        args.forEach((key, value) {
          final placeholder = '{{$key}}';
          final encodedValue = Uri.encodeComponent(value.toString());
          if (url.contains(placeholder)) {
            url = url.replaceAll(placeholder, encodedValue);
          } else {
            if (method == 'GET') {
              queryParams[key] = encodedValue;
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
          response = await _dio.get(url, queryParameters: queryParams, options: options);
        } else {
          response = await _dio.post(url, data: bodyData, queryParameters: queryParams, options: options);
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

  Future<String> _searchWeb(String query, String preferredEngine,
      {String region = 'us-en'}) async {
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
        final results = await _ddgs
            .text(
              query,
              region: region,
              backend: engine,
              maxResults: 5,
            )
            .timeout(const Duration(seconds: 15));
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
}
