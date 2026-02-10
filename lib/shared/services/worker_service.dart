import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:aurora/core/error/app_error_type.dart';
import 'package:aurora/core/error/app_exception.dart';
import 'package:aurora/features/chat/domain/message.dart';
import 'package:aurora/shared/services/llm_service.dart';
import 'package:aurora/features/skills/domain/skill_entity.dart';
import 'package:uuid/uuid.dart';
import 'package:aurora/shared/utils/platform_utils.dart';

enum SkillWorkerMode { reasoner, executor }

class WorkerService {
  final LLMService _llmService;

  WorkerService(this._llmService);

  static const int _defaultMaxTurns = 10;
  static const int _maxAllowedTurns = 30;
  static const Duration _defaultShellTimeout = Duration(seconds: 45);
  static const int _maxPromptFieldChars = 1800;
  static const int _maxManualChars = 8000;
  static const int _maxToolContextChars = 5000;

  Future<String> executeSkillTask(
    Skill skill,
    String skillQuery, {
    String? originalRequest,
    String? model,
    String? providerId,
    int maxTurns = _defaultMaxTurns,
    SkillWorkerMode mode = SkillWorkerMode.reasoner,
    Duration shellTimeout = _defaultShellTimeout,
    void Function({
      required bool success,
      required int promptTokens,
      required int completionTokens,
      required int reasoningTokens,
      required int durationMs,
      AppErrorType? errorType,
    })? onUsage,
  }) async {
    final runtimeShell = PlatformUtils.isWindows ? 'PowerShell' : 'POSIX sh';
    final runtimeOs = Platform.operatingSystem;
    final isSkillCreator = _isSkillCreatorSkill(skill);
    final compactManual = _compactManual(skill.instructions);
    final compactRoutingIntent =
        _trimForPrompt(skillQuery, maxChars: _maxPromptFieldChars);
    final compactOriginalRequest = _trimForPrompt(
        originalRequest ?? 'Not provided',
        maxChars: _maxPromptFieldChars);
    final skillSpecificRules = isSkillCreator
        ? '''
8. **Single Command Per Call**: Execute exactly ONE command in each `run_shell` call. Do not chain with `;`, `&&`, or `||`.
9. **Error-Driven Retry**: If a command fails, output only the next corrected command. Do not claim success.
10. **Init Idempotency**: If init reports "directory already exists", skip init and edit files in place.
11. **Frontmatter Exactness**: For `SKILL.md`, YAML frontmatter must use `---` at start and end.
'''
        : '''
8. **Error-Driven Retry**: If a command fails, output only the next corrected command. Do not claim success.
''';
    final systemPrompt = '''
# You are the Technical Executor for: ${skill.name}
Your ONLY task is to look at the Manual and output the correct shell command to fulfill the request.

## Manual
$compactManual

## Context
- **Routing Intent**: $compactRoutingIntent
- **Original User Request**: $compactOriginalRequest

## Runtime
- **OS**: $runtimeOs
- **Shell**: $runtimeShell

## Strict Rules
1. **No Chitchat**: Only output tool calls or direct answers.
2. **Follow Examples**: Use the exact format and parameter conventions (e.g., English city names) shown in the Manual.
3. **No Summary**: Do NOT summarize the result. Return the raw data or tool output.
4. **Command-Only Tool Args**: The `command` argument must be an executable shell command, not raw source code.
5. **No Markdown Wrappers**: Do not wrap commands in markdown code fences.
6. **Shell Compatibility**: Match commands to the runtime shell. On PowerShell, do NOT use bash heredoc (`<<EOF`) or bash-only syntax.
7. **Multi-line File Writes**: On PowerShell, prefer here-strings (`@'...'@`) with `Set-Content` or `python -` instead of `cat <<EOF`.
$skillSpecificRules
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
        content: skillQuery,
        timestamp: DateTime.now(),
        isUser: true,
      ),
    ];

    final workerTools = [
      {
        'type': 'function',
        'function': {
          'name': 'run_shell',
          'description': 'Execute a shell command as per the manual.',
          'parameters': {
            'type': 'object',
            'required': ['command'],
            'properties': {
              'command': {
                'type': 'string',
                'description': 'The exact command to execute.',
              },
            },
          },
        },
      }
    ];

    final requestStartTime = DateTime.now();
    final safeMaxTurns = maxTurns.clamp(1, _maxAllowedTurns).toInt();
    int totalPromptTokens = 0;
    int totalCompletionTokens = 0;
    int totalReasoningTokens = 0;

    void emitUsage({required bool success, AppErrorType? errorType}) {
      if (onUsage == null) return;
      final durationMs =
          DateTime.now().difference(requestStartTime).inMilliseconds;
      onUsage(
        success: success,
        promptTokens: totalPromptTokens,
        completionTokens: totalCompletionTokens,
        reasoningTokens: totalReasoningTokens,
        durationMs: durationMs,
        errorType: errorType,
      );
    }

    try {
      var success = true;
      String finalOutput =
          'Worker stopped after $safeMaxTurns turns without reaching a final answer.';
      String? lastToolOutput;
      var consecutivePolicyErrors = 0;

      for (var turn = 0; turn < safeMaxTurns; turn++) {
        final response = await _llmService.getResponse(
          messages,
          tools: workerTools,
          model: model,
          providerId: providerId,
        );
        totalPromptTokens += response.promptTokens ?? 0;
        totalCompletionTokens += response.completionTokens ?? 0;
        totalReasoningTokens += response.reasoningTokens ?? 0;

        final toolCalls = response.toolCalls ?? const [];
        if (toolCalls.isNotEmpty) {
          final tc = toolCalls.first;
          if (tc.name != 'run_shell') {
            finalOutput = 'Worker Error: Unsupported tool "${tc.name}".';
            success = false;
            break;
          }

          String command;
          try {
            final args = jsonDecode(tc.arguments ?? '{}');
            if (args is! Map) {
              finalOutput = 'Worker Error: Tool arguments must be an object.';
              success = false;
              break;
            }
            command = args['command']?.toString().trim() ?? '';
          } catch (_) {
            finalOutput = 'Worker Error: Failed to parse tool arguments.';
            success = false;
            break;
          }

          if (command.isEmpty) {
            finalOutput = 'Worker Error: Missing "command" in tool arguments.';
            success = false;
            break;
          }

          final toolCallId = (tc.id ?? '').isNotEmpty
              ? tc.id!
              : 'run_shell_${const Uuid().v4().substring(0, 8)}';

          messages.add(Message(
            id: const Uuid().v4(),
            role: 'assistant',
            content: response.content ?? '',
            timestamp: DateTime.now(),
            isUser: false,
            toolCalls: [
              ToolCall(
                id: toolCallId,
                type: tc.type ?? 'function',
                name: 'run_shell',
                arguments: jsonEncode({'command': command}),
              ),
            ],
          ));

          final toolOutput = await _executeShellCommand(
            command,
            timeout: shellTimeout,
            skillDirectory: skill.path,
            enforceSingleCommand: isSkillCreator,
          );
          final toolOutputForContext = _compactToolOutputForContext(toolOutput);
          messages
              .add(Message.tool(toolOutputForContext, toolCallId: toolCallId));
          finalOutput = toolOutput;
          lastToolOutput = toolOutput;

          if (_isPolicyErrorToolOutput(toolOutput)) {
            consecutivePolicyErrors += 1;
            if (consecutivePolicyErrors >= 3) {
              finalOutput = jsonEncode({
                'error':
                    'PolicyError: Repeated invalid command format. Stop chaining commands and execute one command per call.',
                'exitCode': 2,
              });
              success = false;
              break;
            }
          } else {
            consecutivePolicyErrors = 0;
          }

          if (mode == SkillWorkerMode.executor) {
            break;
          }

          continue;
        }

        final content = response.content?.trim();
        if (content != null && content.isNotEmpty) {
          finalOutput = response.content!;
          break;
        }

        // Some OpenAI-compatible backends may return stop with empty content
        // after a successful tool run. Keep the last tool output instead of
        // overwriting it with a failure marker.
        if (lastToolOutput != null) {
          finalOutput = lastToolOutput;
          break;
        }

        finalOutput = 'Worker: No action performed.';
        success = false;
        break;
      }

      if (finalOutput.startsWith('Worker stopped after')) {
        success = false;
      }
      emitUsage(success: success);
      return finalOutput;
    } catch (e) {
      AppErrorType errorType = AppErrorType.unknown;
      if (e is AppException) {
        errorType = e.type;
      }
      emitUsage(success: false, errorType: errorType);
      return "Worker Critical Error: $e";
    }
  }

  Future<String> _executeShellCommand(
    String command, {
    Duration timeout = _defaultShellTimeout,
    String? skillDirectory,
    bool enforceSingleCommand = false,
  }) async {
    try {
      ProcessResult result;
      var preparedCommand = _normalizeCommand(command);
      if (enforceSingleCommand &&
          skillDirectory != null &&
          skillDirectory.isNotEmpty) {
        preparedCommand = _absolutizeLocalScriptInvocation(
          preparedCommand,
          skillDirectory,
        );
      }
      final policyViolation = _validateWorkerCommand(
        preparedCommand,
        isWindows: PlatformUtils.isWindows,
        enforceSingleCommand: enforceSingleCommand,
      );
      if (policyViolation != null) {
        return jsonEncode({
          'error': policyViolation,
          'exitCode': 2,
        });
      }

      final workingDirectory = _resolveWorkingDirectory(
          preparedCommand, skillDirectory,
          enforceSingleCommand: enforceSingleCommand);
      final environment = PlatformUtils.isWindows
          ? <String, String>{
              'PYTHONUTF8': '1',
              'PYTHONIOENCODING': 'utf-8',
            }
          : <String, String>{};

      if (PlatformUtils.isWindows) {
        preparedCommand = _prepareWindowsCommand(preparedCommand);
        result = await Process.run(
                'powershell.exe', ['-NoProfile', '-Command', preparedCommand],
                workingDirectory: workingDirectory, environment: environment)
            .timeout(timeout);
      } else {
        preparedCommand = _preparePosixCommand(preparedCommand);
        result = await Process.run('sh', ['-c', preparedCommand],
                runInShell: true,
                workingDirectory: workingDirectory,
                environment: environment)
            .timeout(timeout);
      }

      return jsonEncode({
        'stdout': result.stdout.toString(),
        'stderr': result.stderr.toString(),
        'exitCode': result.exitCode,
      });
    } on TimeoutException {
      return jsonEncode({
        'error': 'Command timed out',
        'timeout_seconds': timeout.inSeconds,
        'exitCode': 124,
      });
    } catch (e) {
      return jsonEncode({'error': e.toString()});
    }
  }

  String _normalizeCommand(String command) {
    var normalized = command.trim();
    if (normalized.isEmpty) return normalized;

    // Some backends occasionally return fenced commands despite strict tool
    // instructions. Strip wrappers so the shell receives the raw command.
    normalized = _stripMarkdownCodeFence(normalized);

    if (normalized.startsWith('`') &&
        normalized.endsWith('`') &&
        normalized.length > 1) {
      normalized = normalized.substring(1, normalized.length - 1).trim();
    }

    return normalized;
  }

  String _stripMarkdownCodeFence(String text) {
    final trimmed = text.trim();
    if (!trimmed.startsWith('```')) {
      return text;
    }

    final lines = trimmed.split(RegExp(r'\r?\n'));
    if (lines.length < 3 || lines.last.trim() != '```') {
      return text;
    }

    // Drop opening fence (with optional language marker) and closing fence.
    final body = lines.sublist(1, lines.length - 1).join('\n').trim();
    return body.isEmpty ? text : body;
  }

  bool _looksLikePythonSource(String command) {
    final text = command.trim();
    if (text.isEmpty) return false;

    final isInvocation =
        RegExp(r'^(python(\d+(\.\d+)?)?|py)(\s|$)', caseSensitive: false)
            .hasMatch(text);
    if (isInvocation) return false;

    final patterns = <RegExp>[
      RegExp(r'(^|\n)\s*from\s+\S+\s+import\s+\S+'),
      RegExp(r'(^|\n)\s*import\s+\S+'),
      RegExp(r'(^|\n)\s*def\s+\w+\s*\('),
      RegExp(r'(^|\n)\s*class\s+\w+(\s*\(|\s*:)'),
      RegExp("(^|\\n)\\s*if\\s+__name__\\s*==\\s*['\\\"]__main__['\\\"]\\s*:"),
      RegExp(r'(^|\n)\s*for\s+.+\s+in\s+.+:'),
      RegExp(r'(^|\n)\s*while\s+.+:'),
      RegExp(r'(^|\n)\s*try\s*:'),
      RegExp(r'(^|\n)\s*except(\s+.+)?\s*:'),
    ];

    var hits = 0;
    for (final re in patterns) {
      if (re.hasMatch(text)) hits++;
      if (hits >= 2) return true;
    }

    // Single-line fallback for common direct snippets.
    return RegExp(r'^(from\s+\S+\s+import|import\s+\S+|print\s*\()')
        .hasMatch(text);
  }

  String _wrapPythonSourceForWindows(String source) {
    return "@'\n$source\n'@ | python -";
  }

  String _wrapPythonSourceForPosix(String source) {
    return "python - <<'PY'\n$source\nPY";
  }

  String _prepareWindowsCommand(String command) {
    var trimmed = command.trim();
    trimmed = trimmed.replaceAllMapped(
      RegExp(r'(^|\s)-recursive(\s|$)', caseSensitive: false),
      (m) => '${m.group(1)}-Recurse${m.group(2)}',
    );

    final heredocConverted = _convertBashHeredocToWindows(trimmed);
    if (heredocConverted != null) {
      return heredocConverted;
    }

    if (_looksLikePythonSource(trimmed)) {
      return _wrapPythonSourceForWindows(trimmed);
    }

    final trimmedLeft = trimmed.trimLeft();
    final isPythonInvocation =
        RegExp(r'^(python(\d+(\.\d+)?)?|py)(\s|$)', caseSensitive: false)
            .hasMatch(trimmedLeft);
    if (isPythonInvocation) {
      return trimmed;
    }

    // Claude skills often reference local scripts as `scripts/foo.py`.
    // On Windows, direct execution of .py paths is less reliable than
    // explicit `python scripts/foo.py`, so normalize here.
    final isLocalPyScript = RegExp(
      r'^(?:\.?[\\/])?scripts[\\/].*\.py(?:\s|$)',
      caseSensitive: false,
    ).hasMatch(trimmedLeft);
    if (isLocalPyScript) {
      return 'python $trimmed';
    }
    return trimmed;
  }

  String? _convertBashHeredocToWindows(String command) {
    // Normalize common bash heredoc write:
    // cat << 'EOF' > path/to/file
    // ...
    // EOF
    final heredocPattern = RegExp(
      r'''^cat\s*<<\s*['"]?([A-Za-z0-9_]+)['"]?\s*(>>|>)\s*([^\r\n]+)\r?\n([\s\S]*?)\r?\n\1\s*$''',
      caseSensitive: false,
    );

    final match = heredocPattern.firstMatch(command);
    if (match == null) return null;

    final redirect = match.group(2) ?? '>';
    var path = (match.group(3) ?? '').trim();
    var content = match.group(4) ?? '';
    if (path.isEmpty) return null;

    // Strip surrounding quotes from path if present.
    if ((path.startsWith('"') && path.endsWith('"')) ||
        (path.startsWith("'") && path.endsWith("'"))) {
      path = path.substring(1, path.length - 1);
    }

    // Normalize line endings for deterministic file content.
    content = content.replaceAll('\r\n', '\n');

    final escapedPath = path.replaceAll("'", "''");
    final writer = redirect == '>>' ? 'Add-Content' : 'Set-Content';

    return "@'\n$content\n'@ | $writer -LiteralPath '$escapedPath' -Encoding UTF8";
  }

  String _preparePosixCommand(String command) {
    final trimmed = command.trim();
    if (_looksLikePythonSource(trimmed)) {
      return _wrapPythonSourceForPosix(trimmed);
    }
    return trimmed;
  }

  String _absolutizeLocalScriptInvocation(
      String command, String skillDirectory) {
    final pattern = RegExp(
      r'''^\s*((?:python(?:\d+(?:\.\d+)?)?|py)\s+)(["']?)(?:\./|\.\\)?(scripts[\\/][^"'\s]+)\2([\s\S]*)$''',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(command.trim());
    if (match == null) return command;

    final prefix = match.group(1) ?? '';
    final relativePath = (match.group(3) ?? '').replaceAll('/', '\\');
    final suffix = match.group(4) ?? '';
    if (relativePath.isEmpty) return command;

    final absolutePath =
        '$skillDirectory${Platform.pathSeparator}$relativePath';
    final escapedPath = absolutePath.replaceAll("'", "''");
    return "$prefix'$escapedPath'$suffix";
  }

  String? _resolveWorkingDirectory(
    String command,
    String? skillDirectory, {
    bool enforceSingleCommand = false,
  }) {
    if (skillDirectory == null || skillDirectory.isEmpty) return null;

    // For strict single-command workflows (e.g. skill-creator), keep the
    // default workspace cwd so relative output paths like `--path .` are
    // interpreted in the project context.
    if (enforceSingleCommand) {
      return null;
    }

    final normalized = command.trimLeft().replaceAll('\\', '/');
    final referencesWorkspaceSkillsPath = RegExp(
      r'''(^|[\s"'`=>(/])(?:\./)?skills/''',
      caseSensitive: false,
    ).hasMatch(normalized);

    if (referencesWorkspaceSkillsPath) {
      return null;
    }

    final referencesLocalSkillResource = RegExp(
      r'''(^|\s|["'>])(?:\./)?(?:[A-Za-z0-9._-]+/)*(?:scripts|references|assets)/''',
      caseSensitive: false,
    ).hasMatch(normalized);

    if (referencesLocalSkillResource) {
      return skillDirectory;
    }

    return null;
  }

  bool _isSkillCreatorSkill(Skill skill) {
    final id = skill.id.toLowerCase();
    final name = skill.name.toLowerCase();
    final path = skill.path.toLowerCase();
    return id.contains('skill-creator') ||
        name.contains('skill-creator') ||
        name.contains('skill creator') ||
        path.contains('skill-creator');
  }

  String? _validateWorkerCommand(
    String command, {
    required bool isWindows,
    required bool enforceSingleCommand,
  }) {
    final trimmed = command.trim();
    if (trimmed.isEmpty) {
      return 'PolicyError: Empty command.';
    }

    if (enforceSingleCommand) {
      final hasHereString = trimmed.contains("@'") || trimmed.contains('@"');
      final hasUnquotedSemicolon =
          !hasHereString && _containsUnquotedToken(trimmed, ';');
      if (hasUnquotedSemicolon ||
          _containsUnquotedToken(trimmed, '&&') ||
          _containsUnquotedToken(trimmed, '||')) {
        return 'PolicyError: Use exactly one command per run_shell call. Do not chain with ;, &&, ||.';
      }
    }

    if (isWindows &&
        _containsUnquotedToken(trimmed, '<<') &&
        _convertBashHeredocToWindows(trimmed) == null) {
      return 'PolicyError: Bash heredoc is not supported in PowerShell. Use here-strings with Set-Content/Add-Content or python -.';
    }

    return null;
  }

  bool _containsUnquotedToken(String text, String token) {
    if (text.isEmpty || token.isEmpty) return false;
    var inSingleQuote = false;
    var inDoubleQuote = false;

    for (var i = 0; i < text.length; i++) {
      final ch = text[i];

      // PowerShell escape: skip the next character outside single quotes.
      if (!inSingleQuote && ch == '`') {
        i++;
        continue;
      }

      if (!inDoubleQuote && ch == "'") {
        inSingleQuote = !inSingleQuote;
        continue;
      }
      if (!inSingleQuote && ch == '"') {
        inDoubleQuote = !inDoubleQuote;
        continue;
      }

      if (inSingleQuote || inDoubleQuote) continue;

      if (token.length == 1) {
        if (ch == token) return true;
      } else {
        final end = i + token.length;
        if (end <= text.length && text.substring(i, end) == token) {
          return true;
        }
      }
    }

    return false;
  }

  bool _isPolicyErrorToolOutput(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return false;
      final error = decoded['error']?.toString() ?? '';
      final code = decoded['exitCode'];
      return code == 2 && error.startsWith('PolicyError:');
    } catch (_) {
      return false;
    }
  }

  String _trimForPrompt(String text, {required int maxChars}) {
    final normalized = text.trim();
    if (normalized.length <= maxChars) return normalized;
    final remaining = normalized.length - maxChars;
    return '${normalized.substring(0, maxChars)}\n...[truncated $remaining chars]';
  }

  String _trimMiddle(String text, {required int maxChars}) {
    if (text.length <= maxChars) return text;
    if (maxChars <= 32) return text.substring(0, maxChars);
    final headLen = (maxChars * 0.6).floor();
    final tailLen = maxChars - headLen - 24;
    final head = text.substring(0, headLen);
    final tail = text.substring(text.length - tailLen);
    final removed = text.length - headLen - tailLen;
    return '$head\n...[truncated $removed chars]...\n$tail';
  }

  String _compactManual(String manual) {
    final normalized = manual.trim();
    if (normalized.length <= _maxManualChars) return normalized;

    final lines = normalized.split(RegExp(r'\r?\n'));
    final sectionHints = <String>[];
    final commandHints = <String>[];
    final sectionPattern = RegExp(
      r'^(#{1,6}\s|[0-9]+\.\s|[-*]\s)',
      caseSensitive: false,
    );
    final commandPattern = RegExp(
      r'(scripts?/|\.py\b|init_skill|package_skill|quick_validate|usage:|set-content|add-content|^```(bash|powershell|sh)?)',
      caseSensitive: false,
    );

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final compact = trimmed.length > 180
          ? '${trimmed.substring(0, 180)}...[truncated]'
          : trimmed;

      if (sectionPattern.hasMatch(trimmed) && sectionHints.length < 30) {
        sectionHints.add('- $compact');
      }
      if (commandPattern.hasMatch(trimmed) && commandHints.length < 40) {
        commandHints.add('- $compact');
      }
      if (sectionHints.length >= 30 && commandHints.length >= 40) break;
    }

    final introLen = normalized.length < 700 ? normalized.length : 700;
    final intro = normalized.substring(0, introLen).trim();
    final sectionBlock =
        sectionHints.isEmpty ? '- (none extracted)' : sectionHints.join('\n');
    final commandBlock =
        commandHints.isEmpty ? '- (none extracted)' : commandHints.join('\n');

    final compact = '''$intro

[Manual compacted for runtime reliability]

Key sections:
$sectionBlock

Command and script hints:
$commandBlock''';
    if (compact.length <= _maxManualChars) return compact;
    return _trimMiddle(compact, maxChars: _maxManualChars);
  }

  String _compactToolOutputForContext(String raw) {
    if (raw.length <= _maxToolContextChars) return raw;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final compact = <String, dynamic>{};
        for (final entry in decoded.entries) {
          final key = entry.key;
          final value = entry.value;
          if (value is String) {
            compact[key] = _trimMiddle(value, maxChars: 1200);
          } else {
            compact[key] = value;
          }
        }
        final encoded = jsonEncode(compact);
        return encoded.length <= _maxToolContextChars
            ? encoded
            : _trimMiddle(encoded, maxChars: _maxToolContextChars);
      }
    } catch (_) {}

    return _trimMiddle(raw, maxChars: _maxToolContextChars);
  }
}
