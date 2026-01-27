import 'dart:convert';
import 'dart:io';
import 'package:aurora/features/chat/domain/message.dart';
import 'package:aurora/shared/services/llm_service.dart';
import 'package:aurora/features/skills/domain/skill_entity.dart';
import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:uuid/uuid.dart';

class WorkerService {
  final LLMService _llmService;

  WorkerService(this._llmService);

  Future<String> executeSkillTask(Skill skill, String userRequest, {String? model, String? providerId}) async {
    final systemPrompt = '''
You are an expert executor for the skill: ${skill.name}.
Your goal is to fulfill the User Request by writing and executing scripts using the provided tools.

# Manual for ${skill.name}
${skill.instructions}

# Instructions
1. Analyze the User Request.
2. Refer to the Manual for how to use the skill (Instructions).
3. USE the `run_shell` tool to execute the necessary commands.
4. Output the final result based on the command output.
''';

    final messages = [
      Message(
        id: const Uuid().v4(),
        role: 'system',
        content: systemPrompt,
        timestamp: DateTime.now(),
        isUser: false,
      ),
      Message(
        id: const Uuid().v4(),
        role: 'user',
        content: userRequest,
        timestamp: DateTime.now(),
        isUser: true,
      ),
    ];

    final workerTools = [
      {
        'type': 'function',
        'function': {
          'name': 'run_shell',
          'description': 'Execute a shell command. Use this to run the scripts mentioned in the manual.',
          'parameters': {
            'type': 'object',
            'required': ['command'],
            'properties': {
              'command': {
                'type': 'string',
                'description': 'The command to execute (e.g., python skills/script.py ...)',
              },
            },
          },
        },
      }
    ];

    try {
      final response = await _llmService.getResponse(
        messages,
        tools: workerTools,
        model: model,
        providerId: providerId,
      );

      if (response.toolCalls != null && response.toolCalls!.isNotEmpty) {
        final chunk = response.toolCalls!.first;
        if (chunk.name == 'run_shell') {
          // Fix 1: Handle nullable arguments
          final argsStr = chunk.arguments ?? '{}';
          final args = jsonDecode(argsStr);
          final command = args['command'] as String;

          final result = await _executeShellCommand(command);

          // Fix 2: Handle nullable ID
          final toolCallId = chunk.id ?? '';
          final toolMsg = Message.tool(result, toolCallId: toolCallId);
          
          // Fix 3: Convert ToolCallChunk list to ToolCall list
          final convertedToolCalls = response.toolCalls?.map((c) => ToolCall(
            id: c.id ?? '',
            name: c.name ?? '',
            arguments: c.arguments ?? '',
            type: c.type ?? 'function'
          )).toList();

          messages.add(Message(
             id: const Uuid().v4(),
             role: 'assistant',
             content: '',
             toolCalls: convertedToolCalls,
             timestamp: DateTime.now(),
             isUser: false,
          ));
          messages.add(toolMsg);

          // Optimization: Return result immediately instead of asking LLM to summarize
          // This saves tokens and time, letting the main model handle the summary.
          final outputJson = jsonDecode(result);
          if (outputJson['exitCode'] == 0) {
             return "Execution Success:\n${outputJson['stdout']}";
          } else {
             return "Execution Failed:\nStderr: ${outputJson['stderr']}\nStdout: ${outputJson['stdout']}";
          }
        }
      }

      return response.content ?? "No action taken by worker.";

    } catch (e) {
      return "Worker Error: $e";
    }
  }

  Future<String> _executeShellCommand(String command) async {
    try {
        ProcessResult result;
        if (Platform.isWindows) {
          result = await Process.run('powershell.exe', ['-NoProfile', '-Command', command]);
        } else {
          result = await Process.run('sh', ['-c', command], runInShell: true);
        }
        
        return jsonEncode({
          'stdout': result.stdout.toString(),
          'stderr': result.stderr.toString(),
          'exitCode': result.exitCode,
        });
    } catch (e) {
      return jsonEncode({'error': e.toString()});
    }
  }
}
