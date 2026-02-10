import 'dart:convert';

import '../../chat/domain/message.dart';
import '../../../shared/services/llm_service.dart';
import '../domain/cleaner_directory_planner.dart';
import '../domain/cleaner_models.dart';
import 'heuristic_cleaner_directory_planner.dart';

class LlmCleanerDirectoryPlanner implements CleanerDirectoryPlanner {
  final LLMService llmService;
  final CleanerDirectoryPlanner fallbackPlanner;
  final CleanerAiContext context;

  LlmCleanerDirectoryPlanner({
    required this.llmService,
    required this.context,
    CleanerDirectoryPlanner? fallbackPlanner,
  }) : fallbackPlanner =
            fallbackPlanner ?? const HeuristicCleanerDirectoryPlanner();

  @override
  Future<CleanerDirectoryPlan> plan({
    required List<CleanerDirectoryProfile> profiles,
    required CleanerScanOptions options,
    bool Function()? shouldStop,
  }) async {
    if (profiles.isEmpty) {
      return const CleanerDirectoryPlan(
        selectedPaths: <String>[],
        source: 'llm',
      );
    }
    if (shouldStop?.call() ?? false) {
      return const CleanerDirectoryPlan(
        selectedPaths: <String>[],
        source: 'llm',
      );
    }

    final maxInput = options.llmDirectoryPlanningMaxInputDirectories < 1
        ? 1
        : options.llmDirectoryPlanningMaxInputDirectories;
    final inputs = _buildPlannerInputs(
      profiles,
      maxInput: maxInput,
    );

    if (inputs.isEmpty) {
      return await fallbackPlanner.plan(
        profiles: profiles,
        options: options,
        shouldStop: shouldStop,
      );
    }

    final indexed = <String, CleanerDirectoryProfile>{};
    final inputItems = <Map<String, dynamic>>[];
    for (var i = 0; i < inputs.length; i++) {
      final id = 'd${i + 1}';
      final profile = inputs[i];
      indexed[id] = profile;
      final payload = profile.toAiInput(redactPath: context.redactPaths);
      payload['id'] = id;
      inputItems.add(payload);
    }

    final messages = _buildMessages(
      inputItems: inputItems,
      options: options,
    );

    try {
      final response = await llmService.getResponse(
        messages,
        model: context.model,
        providerId: context.providerId,
      );
      if ((shouldStop?.call() ?? false)) {
        return const CleanerDirectoryPlan(
          selectedPaths: <String>[],
          source: 'llm',
        );
      }

      final raw = (response.content ?? '').trim();
      if (raw.isEmpty) {
        return await fallbackPlanner.plan(
          profiles: profiles,
          options: options,
          shouldStop: shouldStop,
        );
      }

      final parsed = _parseSelection(raw);
      if (parsed == null) {
        return await fallbackPlanner.plan(
          profiles: profiles,
          options: options,
          shouldStop: shouldStop,
        );
      }

      final selectedPaths = <String>[];
      for (final id in parsed.selectedIds) {
        final profile = indexed[id];
        if (profile == null) {
          continue;
        }
        selectedPaths.add(profile.path);
      }

      final byPath = {
        for (final profile in profiles) profile.path.toLowerCase(): profile
      };
      for (final rawPath in parsed.selectedPaths) {
        final profile = byPath[rawPath.trim().toLowerCase()];
        if (profile != null) {
          selectedPaths.add(profile.path);
        }
      }

      if (selectedPaths.isEmpty) {
        return await fallbackPlanner.plan(
          profiles: profiles,
          options: options,
          shouldStop: shouldStop,
        );
      }

      final normalizedSelected = <String>[];
      for (final rawPath in selectedPaths) {
        final normalized = rawPath.trim();
        if (normalized.isEmpty) {
          continue;
        }
        if (normalizedSelected.length >= options.profileSuspiciousDirCount) {
          break;
        }
        if (_hasPathOverlap(normalized, normalizedSelected)) {
          continue;
        }
        normalizedSelected.add(normalized);
      }

      if (normalizedSelected.isEmpty) {
        return await fallbackPlanner.plan(
          profiles: profiles,
          options: options,
          shouldStop: shouldStop,
        );
      }

      return CleanerDirectoryPlan(
        selectedPaths: normalizedSelected,
        source: 'llm',
      );
    } catch (_) {
      return await fallbackPlanner.plan(
        profiles: profiles,
        options: options,
        shouldStop: shouldStop,
      );
    }
  }

  List<CleanerDirectoryProfile> _buildPlannerInputs(
    List<CleanerDirectoryProfile> profiles, {
    required int maxInput,
  }) {
    final sorted = profiles.toList(growable: false)
      ..sort((a, b) {
        final byRoot = (b.userSelectedRoot ? 1 : 0) - (a.userSelectedRoot ? 1 : 0);
        if (byRoot != 0) {
          return byRoot;
        }
        final byScore = b.suspicionScore.compareTo(a.suspicionScore);
        if (byScore != 0) {
          return byScore;
        }
        final byBytes = b.immediateBytes.compareTo(a.immediateBytes);
        if (byBytes != 0) {
          return byBytes;
        }
        return a.depth.compareTo(b.depth);
      });
    if (sorted.length <= maxInput) {
      return sorted;
    }
    return sorted.sublist(0, maxInput);
  }

  List<Message> _buildMessages({
    required List<Map<String, dynamic>> inputItems,
    required CleanerScanOptions options,
  }) {
    final language =
        context.language.toLowerCase().startsWith('zh') ? 'zh-CN' : 'en-US';

    const systemPrompt = '''
You are a cautious storage-cleanup directory triage agent.
You select directories for deep file scanning.

Goal:
- Keep only directories likely to contain disposable data.
- Exclude user valuable folders by default.

Prefer selecting:
- cache, temp, tmp, logs, crash dumps, thumbnails, recycle/trash, package caches, downloads leftovers.

Avoid selecting:
- personal or working content directories such as documents, desktop, pictures/photos, music, videos, projects, source code, repositories.
- system critical directories.

You must return strict JSON only:
{
  "selected_ids": ["d1", "d2"],
  "selected_paths": ["/exact/path/optional"],
  "notes": "short string"
}
''';

    final payload = <String, dynamic>{
      'language': language,
      'max_select': options.profileSuspiciousDirCount,
      'directories': inputItems,
    };

    return <Message>[
      Message(
        id: 'cleaner-directory-plan-system',
        role: 'system',
        isUser: false,
        timestamp: DateTime.now(),
        content: systemPrompt,
      ),
      Message.user(jsonEncode(payload)),
    ];
  }

  _ParsedSelection? _parseSelection(String raw) {
    final decoded = _decodeJsonObject(raw);
    if (decoded == null) {
      return null;
    }

    final selectedIdsValue = decoded['selected_ids'];
    final selectedPathsValue = decoded['selected_paths'];

    final selectedIds = <String>[];
    if (selectedIdsValue is List) {
      for (final value in selectedIdsValue) {
        final text = value.toString().trim();
        if (text.isNotEmpty) {
          selectedIds.add(text);
        }
      }
    }

    final selectedPaths = <String>[];
    if (selectedPathsValue is List) {
      for (final value in selectedPathsValue) {
        final text = value.toString().trim();
        if (text.isNotEmpty) {
          selectedPaths.add(text);
        }
      }
    }

    if (selectedIds.isEmpty && selectedPaths.isEmpty) {
      return null;
    }

    return _ParsedSelection(
      selectedIds: selectedIds,
      selectedPaths: selectedPaths,
    );
  }

  Map<String, dynamic>? _decodeJsonObject(String raw) {
    final normalized = _stripCodeFences(raw.trim());
    final direct = _tryDecodeMap(normalized);
    if (direct != null) {
      return direct;
    }

    final first = normalized.indexOf('{');
    final last = normalized.lastIndexOf('}');
    if (first < 0 || last <= first) {
      return null;
    }
    final sliced = normalized.substring(first, last + 1);
    return _tryDecodeMap(sliced);
  }

  Map<String, dynamic>? _tryDecodeMap(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map) {
        return null;
      }
      final map = <String, dynamic>{};
      decoded.forEach((key, value) {
        if (key is String) {
          map[key] = value;
        }
      });
      return map;
    } catch (_) {
      return null;
    }
  }

  String _stripCodeFences(String value) {
    if (!value.startsWith('```')) {
      return value;
    }
    final lines = value.split(RegExp(r'\r?\n'));
    if (lines.length < 3 || lines.last.trim() != '```') {
      return value;
    }
    return lines.sublist(1, lines.length - 1).join('\n').trim();
  }

  bool _hasPathOverlap(String path, List<String> selectedPaths) {
    for (final selected in selectedPaths) {
      if (_isSameOrUnderPath(path, selected) ||
          _isSameOrUnderPath(selected, path)) {
        return true;
      }
    }
    return false;
  }

  bool _isSameOrUnderPath(String path, String base) {
    var normalizedPath = path.toLowerCase().replaceAll('\\', '/');
    var normalizedBase = base.toLowerCase().replaceAll('\\', '/');
    while (normalizedPath.contains('//')) {
      normalizedPath = normalizedPath.replaceAll('//', '/');
    }
    while (normalizedBase.contains('//')) {
      normalizedBase = normalizedBase.replaceAll('//', '/');
    }
    if (normalizedPath == normalizedBase) {
      return true;
    }
    if (!normalizedBase.endsWith('/')) {
      normalizedBase = '$normalizedBase/';
    }
    return normalizedPath.startsWith(normalizedBase);
  }
}

class _ParsedSelection {
  final List<String> selectedIds;
  final List<String> selectedPaths;

  const _ParsedSelection({
    required this.selectedIds,
    required this.selectedPaths,
  });
}

