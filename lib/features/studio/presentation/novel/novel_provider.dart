import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:aurora/shared/riverpod_compat.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'novel_state.dart';
import 'package:aurora/features/chat/domain/message.dart';
import 'package:aurora/features/knowledge/data/knowledge_storage.dart';
import 'package:aurora/features/knowledge/domain/knowledge_models.dart';
import 'package:aurora/features/knowledge/presentation/knowledge_provider.dart';
import 'package:aurora/shared/services/model_routed_llm_service.dart';
import 'package:aurora/shared/utils/string_utils.dart';
import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:aurora/features/settings/presentation/usage_stats_provider.dart';
import 'package:aurora/core/error/app_error_type.dart';
import 'package:aurora/core/error/app_exception.dart';

part 'novel_prompt_presets.dart';
part 'novel_notifier_workflow_io.dart';

final novelProvider =
    StateNotifierProvider<NovelNotifier, NovelWritingState>((ref) {
  return NovelNotifier(ref);
});

class NovelNotifier extends StateNotifier<NovelWritingState> {
  final Ref _ref;
  bool _shouldStop = false;
  CancelToken? _currentCancelToken;
  late final Future<void> _loadStateFuture;
  bool _isStateLoaded = false;

  Timer? _saveDebounceTimer;
  Future<void> _saveQueue = Future.value();
  Completer<void>? _pendingSaveCompleter;

  NovelNotifier(this._ref) : super(const NovelWritingState()) {
    _loadStateFuture = loadState();
  }

  @override
  void dispose() {
    _saveDebounceTimer?.cancel();
    _currentCancelToken?.cancel('Novel notifier disposed');
    super.dispose();
  }

  KnowledgeStorage get _knowledgeStorage => _ref.read(knowledgeStorageProvider);

  bool _isUsableModelConfig(NovelModelConfig? config) {
    return config != null &&
        config.providerId.trim().isNotEmpty &&
        config.modelId.trim().isNotEmpty;
  }

  Future<void> _waitUntilLoaded() => _loadStateFuture;

  bool _deferUntilLoaded(void Function() action) {
    if (_isStateLoaded) return false;
    unawaited(_loadStateFuture.then((_) {
      if (!mounted) return;
      action();
    }));
    return true;
  }

  void _updateProjectOutlineRequirement(String requirement) {
    final project = state.selectedProject;
    if (project == null) return;

    final trimmed = requirement.trim();
    if (trimmed.isEmpty) return;
    if (project.outlineRequirement == trimmed) return;

    final updatedProject = project.copyWith(outlineRequirement: trimmed);
    final updatedProjects = state.projects
        .map((p) => p.id == updatedProject.id ? updatedProject : p)
        .toList();
    state = state.copyWith(projects: updatedProjects);
    unawaited(_saveState());
  }

  void _restoreProjectStructureFromBackup({
    required String projectId,
    required List<NovelChapter> backupChapters,
    required List<NovelTask> backupTasks,
  }) {
    final currentProject =
        state.projects.where((p) => p.id == projectId).firstOrNull;
    if (currentProject == null) return;

    final currentChapterIds = currentProject.chapters.map((c) => c.id).toSet();
    final remainingTasks = state.allTasks
        .where((t) => !currentChapterIds.contains(t.chapterId))
        .toList();
    final restoredTasks = [...remainingTasks, ...backupTasks];

    final updatedProjects = state.projects
        .map(
            (p) => p.id == projectId ? p.copyWith(chapters: backupChapters) : p)
        .toList();

    final isTargetSelected = state.selectedProjectId == projectId;
    final currentSelectedChapterId = state.selectedChapterId;
    final restoredSelectedChapterId = isTargetSelected
        ? (currentSelectedChapterId != null &&
                backupChapters.any((c) => c.id == currentSelectedChapterId)
            ? currentSelectedChapterId
            : (backupChapters.isNotEmpty ? backupChapters.first.id : null))
        : state.selectedChapterId;

    state = state.copyWith(
      projects: updatedProjects,
      allTasks: restoredTasks,
      selectedChapterId: restoredSelectedChapterId,
      selectedTaskId: isTargetSelected ? null : state.selectedTaskId,
    );
  }

  ProviderConfig? _resolveEmbeddingProvider(SettingsState settings) {
    final providerId =
        settings.knowledgeEmbeddingProviderId ?? settings.activeProviderId;
    for (final provider in settings.providers) {
      if (provider.id == providerId) {
        return provider;
      }
    }
    return null;
  }

  // ========== Project Management ==========
  void createProject(String name, {WorldContext? worldContext}) {
    if (_deferUntilLoaded(
        () => createProject(name, worldContext: worldContext))) {
      return;
    }
    final project = NovelProject.create(name, worldContext: worldContext);
    state = state.copyWith(
      projects: [...state.projects, project],
      selectedProjectId: project.id,
      selectedChapterId:
          project.chapters.isNotEmpty ? project.chapters.first.id : null,
    );
    unawaited(_saveState());
    unawaited(_ensureProjectKnowledgeBase(project.id));
  }

  void selectProject(String projectId) {
    if (_deferUntilLoaded(() => selectProject(projectId))) return;
    final project = state.projects.firstWhere((p) => p.id == projectId);
    state = state.copyWith(
      selectedProjectId: projectId,
      selectedChapterId:
          project.chapters.isNotEmpty ? project.chapters.first.id : null,
      selectedTaskId: null,
    );
    unawaited(_saveState());
    unawaited(_ensureProjectKnowledgeBase(projectId));
  }

  void deleteProject(String projectId) {
    if (_deferUntilLoaded(() => deleteProject(projectId))) return;
    final updatedProjects =
        state.projects.where((p) => p.id != projectId).toList();
    final project = state.projects.firstWhere((p) => p.id == projectId);
    final updatedTasks = state.allTasks.where((t) {
      return !project.chapters.any((c) => c.id == t.chapterId);
    }).toList();

    state = state.copyWith(
      projects: updatedProjects,
      allTasks: updatedTasks,
      selectedProjectId:
          updatedProjects.isNotEmpty ? updatedProjects.first.id : null,
      selectedChapterId: null,
      selectedTaskId: null,
    );
    unawaited(_saveState());
    unawaited(_knowledgeStorage.deleteProjectBase(projectId));
  }

  // ========== Outline Management ==========
  Future<void> generateOutline(String requirement) async {
    await _waitUntilLoaded();
    if (state.selectedProject == null) return;
    final trimmedRequirement = requirement.trim();
    if (trimmedRequirement.isEmpty) return;

    _updateProjectOutlineRequirement(trimmedRequirement);

    // 开始生成大纲，设置 loading 状态
    state = state.copyWith(isGeneratingOutline: true);

    final outlineConfig = state.outlineModel;

    if (!_isUsableModelConfig(outlineConfig)) {
      // Fallback: use requirement as outline directly
      _updateProjectOutline('【故事需求】\n$trimmedRequirement\n\n（请编辑此大纲后点击"生成章节"）');
      state = state.copyWith(isGeneratingOutline: false);
      return;
    }

    _shouldStop = false;
    _currentCancelToken?.cancel();
    _currentCancelToken = CancelToken();

    try {
      final activeOutlineConfig = outlineConfig!;
      final systemPrompt = activeOutlineConfig.systemPrompt.isNotEmpty
          ? activeOutlineConfig.systemPrompt
          : NovelPromptPresets.outline;

      final result = await _callLLM(
          activeOutlineConfig, systemPrompt, trimmedRequirement,
          cancelToken: _currentCancelToken);
      _updateProjectOutline(result);
    } catch (e) {
      _updateProjectOutline('生成大纲失败：$e\n\n原始需求：\n$trimmedRequirement');
    }

    // 生成完成，清除 loading 状态
    state = state.copyWith(isGeneratingOutline: false);
    _currentCancelToken = null;
  }

  Future<void> rerunOutline() async {
    await _waitUntilLoaded();
    final requirement = state.selectedProject?.outlineRequirement?.trim() ?? '';
    if (requirement.isEmpty) return;
    await generateOutline(requirement);
  }

  void _updateProjectOutline(String outline) {
    if (_deferUntilLoaded(() => _updateProjectOutline(outline))) return;
    if (state.selectedProject == null) return;

    final updatedProject = state.selectedProject!.copyWith(outline: outline);
    final updatedProjects = state.projects
        .map((p) => p.id == updatedProject.id ? updatedProject : p)
        .toList();

    state = state.copyWith(projects: updatedProjects);
    unawaited(_saveState());
  }

  void updateProjectOutline(String outline) {
    _updateProjectOutline(outline);
  }

  void clearChaptersAndTasks() {
    if (_deferUntilLoaded(() => clearChaptersAndTasks())) return;
    if (state.selectedProject == null) return;

    final updatedProject = state.selectedProject!.copyWith(chapters: []);
    final updatedProjects = state.projects
        .map((p) => p.id == updatedProject.id ? updatedProject : p)
        .toList();

    // Remove all tasks for this project's chapters
    final projectChapterIds =
        state.selectedProject!.chapters.map((c) => c.id).toSet();
    final updatedTasks = state.allTasks
        .where((t) => !projectChapterIds.contains(t.chapterId))
        .toList();

    state = state.copyWith(
      projects: updatedProjects,
      allTasks: updatedTasks,
      selectedChapterId: null,
      selectedTaskId: null,
    );
    unawaited(_saveState());
  }

  /// 重新执行所有任务：重置所有任务状态，清空已生成内容，从头开始
  void restartAllTasks() {
    if (_deferUntilLoaded(() => restartAllTasks())) return;
    if (state.selectedProject == null) return;

    final projectChapterIds =
        state.selectedProject!.chapters.map((c) => c.id).toSet();

    // Reset all tasks in this project to pending status, clear content and feedback
    final updatedTasks = state.allTasks.map((t) {
      if (projectChapterIds.contains(t.chapterId)) {
        return t.copyWith(
          status: TaskStatus.pending,
          content: null,
          reviewFeedback: null,
          retryCount: 0,
        );
      }
      return t;
    }).toList();

    state = state.copyWith(
      allTasks: updatedTasks,
      isRunning: false,
      isPaused: false,
    );
    unawaited(_saveState());
  }

  // ========== World Context Management ==========
  // ========== Style Imitation ==========
  void updateStyleSample(String text) {
    final project = state.selectedProject;
    if (project == null) return;

    if (project.styleSample == text) return;

    final updatedProject = project.copyWith(
      styleSample: text,
      analyzedStyle: null,
    );
    final updatedProjects = state.projects
        .map((p) => p.id == updatedProject.id ? updatedProject : p)
        .toList();
    state = state.copyWith(projects: updatedProjects);
    unawaited(_saveState());
  }

  void clearStyleSample() {
    final project = state.selectedProject;
    if (project == null) return;

    final updatedProject = project.copyWith(
      styleSample: null,
      analyzedStyle: null,
    );
    final updatedProjects = state.projects
        .map((p) => p.id == updatedProject.id ? updatedProject : p)
        .toList();
    state = state.copyWith(projects: updatedProjects);
    unawaited(_saveState());
  }

  Future<void> analyzeWritingStyle() async {
    if (state.isAnalyzingStyle) return;

    final selectedProject = state.selectedProject;
    if (selectedProject == null) return;
    final projectId = selectedProject.id;
    final sampleSnapshot = selectedProject.styleSample ?? '';
    if (sampleSnapshot.trim().isEmpty) return;

    // Use decompose model for analysis, fallback to writer model
    final analyzerConfig = state.decomposeModel ?? state.writerModel;
    if (!_isUsableModelConfig(analyzerConfig)) {
      throw Exception('No model configured for style analysis');
    }

    state = state.copyWith(isAnalyzingStyle: true);

    try {
      final result = await _callLLM(
        analyzerConfig!,
        NovelPromptPresets.styleAnalyzer,
        '请分析以下例文的文风特征：\n\n$sampleSnapshot',
      );

      // Update the project with the analyzed style
      NovelProject? latestProject;
      for (final p in state.projects) {
        if (p.id == projectId) {
          latestProject = p;
          break;
        }
      }
      if (latestProject == null) return;
      if ((latestProject.styleSample ?? '') != sampleSnapshot) return;

      final updatedProject =
          latestProject.copyWith(analyzedStyle: result.trim());
      final updatedProjects =
          state.projects.map((p) => p.id == projectId ? updatedProject : p);
      state = state.copyWith(projects: updatedProjects.toList());
    } finally {
      state = state.copyWith(isAnalyzingStyle: false);
      unawaited(_saveState());
    }
  }

  // ========== World Context ==========
  void updateWorldContext(WorldContext context) {
    if (_deferUntilLoaded(() => updateWorldContext(context))) return;
    if (state.selectedProject == null) return;

    final updatedProject =
        state.selectedProject!.copyWith(worldContext: context);
    final updatedProjects = state.projects
        .map((p) => p.id == updatedProject.id ? updatedProject : p)
        .toList();

    state = state.copyWith(projects: updatedProjects);
    unawaited(_saveState());
  }

  /// 清空世界设定数据，但保留开关状态
  void clearWorldContext() {
    if (_deferUntilLoaded(() => clearWorldContext())) return;
    if (state.selectedProject == null) return;

    final ctx = state.selectedProject!.worldContext;
    final clearedContext = WorldContext(
      rules: const {},
      characters: const {},
      relationships: const {},
      locations: const {},
      foreshadowing: const [],
      // 保留 include 开关状态
      includeRules: ctx.includeRules,
      includeCharacters: ctx.includeCharacters,
      includeRelationships: ctx.includeRelationships,
      includeLocations: ctx.includeLocations,
      includeForeshadowing: ctx.includeForeshadowing,
    );
    updateWorldContext(clearedContext);
  }

  void toggleContextCategory(String category, bool enabled) {
    if (_deferUntilLoaded(() => toggleContextCategory(category, enabled))) {
      return;
    }
    if (state.selectedProject == null) return;

    final ctx = state.selectedProject!.worldContext;
    WorldContext updated;
    switch (category) {
      case 'characters':
        updated = ctx.copyWith(includeCharacters: enabled);
        break;
      case 'relationships':
        updated = ctx.copyWith(includeRelationships: enabled);
        break;
      case 'locations':
        updated = ctx.copyWith(includeLocations: enabled);
        break;
      case 'foreshadowing':
        updated = ctx.copyWith(includeForeshadowing: enabled);
        break;
      case 'rules':
        updated = ctx.copyWith(includeRules: enabled);
        break;
      default:
        return;
    }
    updateWorldContext(updated);
  }

  /// Auto-extract context changes from completed chapter content (Data Agent)
  Future<void> _extractContextUpdates(String content) async {
    if (state.selectedProject == null) return;

    // 优先用大纲模型提取；失败时降级到写作模型，避免单模型抖动导致全量丢失
    final extractorCandidates = <NovelModelConfig>[];
    if (_isUsableModelConfig(state.outlineModel)) {
      extractorCandidates.add(state.outlineModel!);
    }
    if (_isUsableModelConfig(state.writerModel)) {
      final writer = state.writerModel!;
      final duplicate = extractorCandidates.any(
        (m) => m.providerId == writer.providerId && m.modelId == writer.modelId,
      );
      if (!duplicate) {
        extractorCandidates.add(writer);
      }
    }
    if (extractorCandidates.isEmpty) return;

    try {
      Map<String, dynamic>? updates;
      Object? lastError;

      for (final extractorModel in extractorCandidates) {
        try {
          final result = await _callLLM(
            extractorModel,
            NovelPromptPresets.contextExtractor,
            content,
            cancelToken: _currentCancelToken,
          );

          if (_shouldStop) return;

          final decoded = jsonDecode(_cleanJson(result));
          if (decoded is Map<String, dynamic>) {
            updates = decoded;
            break;
          }
          if (decoded is Map) {
            updates = decoded.map(
              (key, value) => MapEntry(key.toString(), value),
            );
            break;
          }
          lastError = 'Context extractor returned non-object JSON.';
        } catch (e) {
          lastError = e;
        }
      }

      if (updates == null) {
        debugPrint('[NOVEL][WARN] Context extraction skipped: $lastError');
        return;
      }

      final ctx = state.selectedProject!.worldContext;

      // Merge updates into existing context
      final newCharacters = Map<String, String>.from(ctx.characters);
      final newRules = Map<String, String>.from(ctx.rules);
      final newRelationships = Map<String, String>.from(ctx.relationships);
      final newLocations = Map<String, String>.from(ctx.locations);
      final newForeshadowing = List<String>.from(ctx.foreshadowing);

      // 处理新角色
      newCharacters.addAll(_toStringMap(updates['newCharacters']));

      // 处理角色状态更新（Data Agent 核心功能）
      // 当角色发生变化时（如升级、获得物品），更新其描述
      final charUpdates = _toStringMap(updates['characterUpdates']);
      for (final entry in charUpdates.entries) {
        final charName = entry.key;
        final updateDesc = entry.value;
        if (newCharacters.containsKey(charName)) {
          // 追加状态变化到现有描述
          final existing = newCharacters[charName]!;
          newCharacters[charName] = '$existing【最新】$updateDesc';
        } else {
          // 如果角色不存在，作为新角色添加
          newCharacters[charName] = updateDesc;
        }
      }

      // 处理新规则
      newRules.addAll(_toStringMap(updates['newRules']));

      // 处理规则状态更新
      final ruleUpdates = _toStringMap(updates['ruleUpdates']);
      for (final entry in ruleUpdates.entries) {
        final ruleName = entry.key;
        final updateDesc = entry.value;
        if (newRules.containsKey(ruleName)) {
          final existing = newRules[ruleName]!;
          newRules[ruleName] = '$existing【最新】$updateDesc';
        } else {
          newRules[ruleName] = updateDesc;
        }
      }

      newRelationships.addAll(_toStringMap(updates['updatedRelationships']));
      newLocations.addAll(_toStringMap(updates['newLocations']));

      final newItems = _toStringList(updates['newForeshadowing']);
      for (final item in newItems) {
        if (!newForeshadowing.contains(item)) {
          newForeshadowing.add(item);
        }
      }

      final resolved = _toStringList(updates['resolvedForeshadowing']);
      newForeshadowing.removeWhere((f) => resolved.contains(f));

      updateWorldContext(ctx.copyWith(
        characters: newCharacters,
        rules: newRules,
        relationships: newRelationships,
        locations: newLocations,
        foreshadowing: newForeshadowing,
      ));
    } catch (e) {
      debugPrint('[NOVEL][WARN] Context extraction failed: $e');
    }
  }

  Map<String, String> _toStringMap(dynamic raw) {
    if (raw is! Map) return const {};
    final result = <String, String>{};
    raw.forEach((key, value) {
      final k = key.toString().trim();
      final v = value?.toString().trim() ?? '';
      if (k.isNotEmpty && v.isNotEmpty) {
        result[k] = v;
      }
    });
    return result;
  }

  List<String> _toStringList(dynamic raw) {
    if (raw is! List) return const [];
    final result = <String>[];
    for (final item in raw) {
      final text = item?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        result.add(text);
      }
    }
    return result;
  }

  // ========== Chapter Management ==========
  void addChapter(String title) {
    if (_deferUntilLoaded(() => addChapter(title))) return;
    if (state.selectedProject == null) return;

    final newChapter = NovelChapter(
      id: const Uuid().v4(),
      title: title,
      order: state.selectedProject!.chapters.length,
    );

    final updatedProject = state.selectedProject!.copyWith(
      chapters: [...state.selectedProject!.chapters, newChapter],
    );

    final updatedProjects = state.projects.map((p) {
      return p.id == updatedProject.id ? updatedProject : p;
    }).toList();

    state = state.copyWith(
      projects: updatedProjects,
      selectedChapterId: newChapter.id,
    );
    unawaited(_saveState());
  }

  void selectChapter(String chapterId) {
    if (_deferUntilLoaded(() => selectChapter(chapterId))) return;
    state = state.copyWith(selectedChapterId: chapterId, selectedTaskId: null);
    unawaited(_saveState());
  }

  void deleteChapter(String chapterId) {
    if (_deferUntilLoaded(() => deleteChapter(chapterId))) return;
    if (state.selectedProject == null) return;

    final updatedChapters = state.selectedProject!.chapters
        .where((c) => c.id != chapterId)
        .toList();
    final updatedProject =
        state.selectedProject!.copyWith(chapters: updatedChapters);
    final updatedProjects = state.projects
        .map((p) => p.id == updatedProject.id ? updatedProject : p)
        .toList();
    final updatedTasks =
        state.allTasks.where((t) => t.chapterId != chapterId).toList();

    state = state.copyWith(
      projects: updatedProjects,
      allTasks: updatedTasks,
      selectedChapterId:
          updatedChapters.isNotEmpty ? updatedChapters.first.id : null,
    );
    unawaited(_saveState());
  }

  // ========== Task Management ==========
  void addTask(String description) {
    if (_deferUntilLoaded(() => addTask(description))) return;
    if (state.selectedChapterId == null) return;

    final task = NovelTask(
      id: const Uuid().v4(),
      chapterId: state.selectedChapterId!,
      description: description,
      status: TaskStatus.pending,
    );
    state = state.copyWith(allTasks: [...state.allTasks, task]);
    unawaited(_saveState());
  }

  void selectTask(String taskId) {
    if (_deferUntilLoaded(() => selectTask(taskId))) return;
    state = state.copyWith(selectedTaskId: taskId);
  }

  /// Decompose the project's outline into chapters (Multi-stage Batch Processing)
  Future<void> decomposeFromOutline() async {
    await _waitUntilLoaded();
    final selectedProject = state.selectedProject;
    if (selectedProject == null) return;

    final projectId = selectedProject.id;
    final outline = selectedProject.outline;
    if (outline == null || outline.isEmpty) return;

    final backupChapters = List<NovelChapter>.from(selectedProject.chapters);
    final backupChapterIds = backupChapters.map((c) => c.id).toSet();
    final backupTasks = state.allTasks
        .where((t) => backupChapterIds.contains(t.chapterId))
        .toList();

    // 开始拆解，设置 loading 状态
    state = state.copyWith(
      isDecomposing: true,
      decomposeStatus: '阶段 1/2：正在规划章节列表…',
      decomposeCurrentBatch: 0,
      decomposeTotalBatches: 0,
    );

    final decomposeConfig = state.decomposeModel;
    if (!_isUsableModelConfig(decomposeConfig)) {
      state = state.copyWith(
        isDecomposing: false,
        decomposeStatus: '细纲模型未配置，无法执行拆解。',
        decomposeCurrentBatch: 0,
        decomposeTotalBatches: 0,
      );
      return;
    }

    var completedSuccessfully = false;
    String? rollbackReason;

    try {
      final activeDecomposeConfig = decomposeConfig!;
      _shouldStop = false;
      _currentCancelToken?.cancel();
      _currentCancelToken = CancelToken();

      // --- 第一阶段：获取完整的章节标题列表 ---
      debugPrint('[NOVEL][INFO] Phase 1: planning chapter list.');
      final listResult = await _callLLM(
        activeDecomposeConfig,
        NovelPromptPresets.chapterListPlanner,
        '大纲内容如下：\n$outline',
        cancelToken: _currentCancelToken,
      );

      final List<String> allTitles =
          List<String>.from(jsonDecode(_cleanJson(listResult)));
      if (allTitles.isEmpty) throw Exception('No chapters planned.');

      debugPrint(
          '[NOVEL][INFO] Planned ${allTitles.length} chapters; starting batch detailing.');

      // --- 第二阶段：分批次填充详细细纲 ---
      const int batchSize = 10; // 每批处理10章，提高效率的同时保持足够的描述细节
      final totalBatches = (allTitles.length / batchSize).ceil();
      state = state.copyWith(
        decomposeStatus: '阶段 2/2：共 $totalBatches 批，开始生成细纲…',
        decomposeCurrentBatch: 0,
        decomposeTotalBatches: totalBatches,
      );

      final List<NovelChapter> allNewChapters = [];
      final List<NovelTask> allNewTasks = [];
      String runningContext = '书籍初始状态：一切尚待开始。';
      var autoFilledChapters = 0;

      for (int i = 0; i < allTitles.length; i += batchSize) {
        if (_shouldStop) {
          rollbackReason = '拆解已停止，已恢复到拆解前内容。';
          break;
        }

        const int maxRetries = 2;
        bool batchSuccess = false;
        final batchNo = (i ~/ batchSize) + 1;
        final end = (i + batchSize < allTitles.length)
            ? i + batchSize
            : allTitles.length;
        final batchTitles = allTitles.sublist(i, end);

        state = state.copyWith(
          decomposeCurrentBatch: batchNo,
          decomposeStatus:
              '阶段 2/2：正在处理第 $batchNo/$totalBatches 批（第 ${i + 1}-$end 章）…',
        );

        for (int retry = 0; retry <= maxRetries; retry++) {
          try {
            if (retry > 0) {
              debugPrint(
                  '[NOVEL][INFO] Retrying batch ${i + 1} (attempt ${retry + 1}/3).');
              await Future.delayed(const Duration(seconds: 1));
            }

            debugPrint(
                '[NOVEL][INFO] Processing batch: ${i + 1}-$end/${allTitles.length}.');

            final detailPrompt = '以下是全书大纲：\n$outline\n\n'
                '【前文进度总结】：\n$runningContext\n\n'
                '请针对以下章节列表生成剧本级细纲：\n${batchTitles.join('\n')}';

            final systemPrompt = activeDecomposeConfig.systemPrompt.isNotEmpty
                ? activeDecomposeConfig.systemPrompt
                : NovelPromptPresets.decompose;

            final detailResult = await _callLLM(
                activeDecomposeConfig, systemPrompt, detailPrompt,
                cancelToken: _currentCancelToken);
            final dynamic decodedData = jsonDecode(_cleanJson(detailResult));

            List<dynamic> detailedChaptersRaw = [];
            if (decodedData is List) {
              detailedChaptersRaw = decodedData;
            } else if (decodedData is Map &&
                decodedData.containsKey('chapters')) {
              detailedChaptersRaw = decodedData['chapters'] as List<dynamic>;
            }

            final detailedEntries = <Map<String, String>>[];
            for (final item in detailedChaptersRaw) {
              if (item is! Map) continue;
              final map = item.cast<dynamic, dynamic>();
              final title = (map['title'] ?? '').toString().trim();
              final description = (map['description'] ?? '').toString().trim();
              if (title.isEmpty && description.isEmpty) continue;
              detailedEntries.add({
                'title': title,
                'description': description,
              });
            }

            if (detailedEntries.isEmpty) {
              throw Exception('Batch returned empty chapter details.');
            }

            String batchContentForSummary = '';
            for (int chapterIndex = 0;
                chapterIndex < batchTitles.length;
                chapterIndex++) {
              final chapterId = const Uuid().v4();
              final expectedTitle = batchTitles[chapterIndex];

              String description;
              if (chapterIndex < detailedEntries.length &&
                  detailedEntries[chapterIndex]['description'] != null &&
                  detailedEntries[chapterIndex]['description']!
                      .trim()
                      .isNotEmpty) {
                description =
                    detailedEntries[chapterIndex]['description']!.trim();
              } else {
                autoFilledChapters++;
                description = '【自动补位】该章节细纲在拆解过程中丢失。请先补充本章细纲，再执行写作任务。';
              }

              batchContentForSummary +=
                  '标题：$expectedTitle\n内容概要：$description\n---\n';

              final chapter = NovelChapter(
                id: chapterId,
                title: expectedTitle,
                order: allNewChapters.length,
              );

              final task = NovelTask(
                id: const Uuid().v4(),
                chapterId: chapterId,
                description: description,
                status: TaskStatus.pending,
              );

              allNewChapters.add(chapter);
              allNewTasks.add(task);
            }

            // --- 专项总结阶段：解耦调用总结官 ---
            try {
              debugPrint('[NOVEL][INFO] Summarizing batch for next context.');
              final summaryInput =
                  '【本批次细纲内容】：\n$batchContentForSummary\n\n【旧进度总结】：\n$runningContext';
              final summaryResult = await _callLLM(activeDecomposeConfig,
                  NovelPromptPresets.batchSummarizer, summaryInput);
              runningContext = _cleanJson(summaryResult);
            } catch (e) {
              debugPrint(
                  '[NOVEL][WARN] Summarization failed; using basic concatenation: $e');
              runningContext += '\n(由于总结失败，仅记录标题) ${batchTitles.join(', ')}';
            }

            // 每一批次更新一次 UI 进度
            final currentProject = state.selectedProject!;
            final updatedProject = currentProject.copyWith(
              chapters: [...allNewChapters],
            );
            final updatedProjects = state.projects
                .map((p) => p.id == updatedProject.id ? updatedProject : p)
                .toList();

            state = state.copyWith(
              projects: updatedProjects,
              allTasks: [
                ...state.allTasks.where((t) => !_isTaskInProject(t, projectId)),
                ...allNewTasks
              ],
              decomposeStatus:
                  '阶段 2/2：已完成第 $batchNo/$totalBatches 批（累计 ${allNewChapters.length}/${allTitles.length} 章）',
            );
            unawaited(_saveState());

            batchSuccess = true;
            break; // 成功则跳出重试循环
          } catch (e) {
            debugPrint('[NOVEL][WARN] Batch attempt ${retry + 1} failed: $e');
            if (retry == maxRetries) {
              throw Exception(
                  'Batch $batchNo/$totalBatches failed after retries: $e');
            }
          }
        }

        if (!batchSuccess) break;
      }

      if (!_shouldStop && allNewChapters.length == allTitles.length) {
        completedSuccessfully = true;
        state = state.copyWith(
          decomposeStatus: autoFilledChapters > 0
              ? '细纲生成完成：$autoFilledChapters 章已自动补位，请重点检查这些章节。'
              : '细纲生成完成：全部章节细纲已生成。',
        );
      } else if (!_shouldStop) {
        rollbackReason = '细纲生成不完整，已恢复到拆解前内容。';
      }
    } catch (e) {
      debugPrint('[NOVEL][ERROR] Decomposition failed: $e');
      rollbackReason = '细纲生成异常，已恢复到拆解前内容：$e';
    } finally {
      if (!completedSuccessfully) {
        _restoreProjectStructureFromBackup(
          projectId: projectId,
          backupChapters: backupChapters,
          backupTasks: backupTasks,
        );
        state = state.copyWith(
          decomposeStatus: rollbackReason ?? '细纲生成未完成，已恢复到拆解前内容。',
        );
      }

      state = state.copyWith(
        isDecomposing: false,
        decomposeCurrentBatch: 0,
        decomposeTotalBatches: 0,
      );
      _currentCancelToken = null;
      unawaited(_saveState(immediate: true));
    }
  }

  String _cleanJson(String content) {
    if (content.isEmpty) return '[]';

    String jsonContent = content.trim();

    // 1. 提取 Markdown 代码块中的内容
    if (jsonContent.contains('```')) {
      // 尝试匹配 ```json ... ``` 或 ``` ... ```
      final RegExp codeBlockRegExp =
          RegExp(r'```(?:json)?\s*([\s\S]*?)(?:```|$)');
      final match = codeBlockRegExp.firstMatch(jsonContent);
      if (match != null && match.groupCount >= 1) {
        jsonContent = match.group(1)!.trim();
      }
    }

    // 2. 找到第一个 [ 或 {
    int firstBracket = jsonContent.indexOf('[');
    int firstBrace = jsonContent.indexOf('{');
    int start = -1;
    if (firstBracket != -1 && firstBrace != -1) {
      start = firstBracket < firstBrace ? firstBracket : firstBrace;
    } else {
      start = firstBracket != -1 ? firstBracket : firstBrace;
    }

    if (start == -1) return '[]'; // 没找到 JSON 结构

    jsonContent = jsonContent.substring(start);

    // 3. 尝试修复截断的 JSON
    return _repairJson(jsonContent);
  }

  String _repairJson(String json) {
    if (json.isEmpty) return '[]';

    String repaired = json.trim();
    List<String> stack = [];
    bool inString = false;
    bool escaped = false;

    int lastValidPos = -1;

    for (int i = 0; i < repaired.length; i++) {
      String char = repaired[i];

      if (escaped) {
        escaped = false;
        continue;
      }

      if (char == '\\') {
        escaped = true;
        continue;
      }

      if (char == '"') {
        inString = !inString;
        continue;
      }

      if (!inString) {
        if (char == '[' || char == '{') {
          stack.add(char);
        } else if (char == ']') {
          if (stack.isNotEmpty && stack.last == '[') {
            stack.removeLast();
            if (stack.isEmpty) lastValidPos = i;
          }
        } else if (char == '}') {
          if (stack.isNotEmpty && stack.last == '{') {
            stack.removeLast();
            if (stack.isEmpty) lastValidPos = i;
          }
        }
      }
    }

    // 如果 JSON 已经完整（栈为空），但后面跟着杂质（如 extra quotes）
    if (stack.isEmpty &&
        lastValidPos != -1 &&
        lastValidPos < repaired.length - 1) {
      repaired = repaired.substring(0, lastValidPos + 1);
    }

    // 如果在字符串内部截断，先闭合字符串
    if (inString) {
      repaired += '"';
    }

    // 补齐缺失的括号（倒序补齐）
    while (stack.isNotEmpty) {
      String last = stack.removeLast();
      if (last == '[') {
        repaired += ']';
      } else if (last == '{') {
        repaired += '}';
      }
    }

    try {
      jsonDecode(repaired);
      return repaired;
    } catch (_) {
      return repaired;
    }
  }

  void updateTaskStatus(String taskId, TaskStatus status) {
    _updateTaskStatus(taskId, status);
  }

  Future<void> approveTask(String taskId) async {
    await _waitUntilLoaded();
    final task = state.allTasks.firstWhere(
      (t) => t.id == taskId,
      orElse: () => const NovelTask(id: '', chapterId: '', description: ''),
    );
    if (task.id.isEmpty) return;

    _updateTaskStatus(taskId, TaskStatus.success);

    final content = task.content?.trim() ?? '';
    if (content.isNotEmpty) {
      await _extractContextUpdates(content);
    }
  }

  /// Execute a single task (called when user clicks "Run Task" button)
  Future<void> runSingleTask(String taskId) async {
    await _waitUntilLoaded();
    if (state.isRunning) return;

    final task = state.allTasks.firstWhere(
      (t) => t.id == taskId,
      orElse: () => NovelTask(
          id: '', chapterId: '', description: '', status: TaskStatus.pending),
    );

    if (task.id.isEmpty) return;
    if (task.status == TaskStatus.running) return; // Already running

    // Reset retry count and clear feedback when manually triggered
    final updatedTasks = state.allTasks.map((t) {
      if (t.id == taskId) {
        return t.copyWith(
          retryCount: 0,
          reviewFeedback: '',
          status: TaskStatus.pending,
        );
      }
      return t;
    }).toList();
    state = state.copyWith(allTasks: updatedTasks);

    _shouldStop = false;
    _currentCancelToken?.cancel('Starting single task');
    _currentCancelToken = CancelToken();

    try {
      await _executeTask(taskId);
    } finally {
      if (!state.isRunning) {
        _currentCancelToken = null;
      }
    }
  }

  void updateTaskDescription(String taskId, String newDescription) {
    if (_deferUntilLoaded(
        () => updateTaskDescription(taskId, newDescription))) {
      return;
    }
    final updatedTasks = state.allTasks.map((t) {
      if (t.id == taskId) {
        return t.copyWith(description: newDescription);
      }
      return t;
    }).toList();
    state = state.copyWith(allTasks: updatedTasks);
    unawaited(_saveState());
  }

  void deleteTask(String taskId) {
    if (_deferUntilLoaded(() => deleteTask(taskId))) return;
    state = state.copyWith(
      allTasks: state.allTasks.where((t) => t.id != taskId).toList(),
      selectedTaskId:
          state.selectedTaskId == taskId ? null : state.selectedTaskId,
    );
    unawaited(_saveState());
  }

  // ========== Controls ==========
  bool hasRunnableTasksInSelectedProject() {
    final project = state.selectedProject;
    if (project == null) return false;
    final chapterIds = project.chapters.map((c) => c.id).toSet();
    return state.allTasks.any((t) =>
        chapterIds.contains(t.chapterId) &&
        (t.status == TaskStatus.pending || t.status == TaskStatus.failed));
  }

  void togglePause() {
    if (_deferUntilLoaded(() => togglePause())) return;
    state = state.copyWith(isPaused: !state.isPaused);
    unawaited(_saveState());
  }

  void toggleReviewMode(bool enabled) {
    if (_deferUntilLoaded(() => toggleReviewMode(enabled))) return;
    state = state.copyWith(isReviewEnabled: enabled);
    unawaited(_saveState());
  }

  void startQueue() {
    if (_deferUntilLoaded(startQueue)) return;
    unawaited(runWorkflow());
  }

  void stopQueue() {
    if (_deferUntilLoaded(stopQueue)) return;
    _shouldStop = true;
    _currentCancelToken?.cancel('User stopped queue');
    _currentCancelToken = null;

    // 重置所有正在运行的任务状态为 pending，避免一直转圈
    final updatedTasks = state.allTasks.map((t) {
      if (t.status == TaskStatus.running || t.status == TaskStatus.reviewing) {
        return t.copyWith(status: TaskStatus.pending);
      }
      return t;
    }).toList();

    state = state.copyWith(
      isRunning: false,
      isPaused: false,
      isDecomposing: false, // 也重置拆解状态
      decomposeStatus: '任务已停止。',
      decomposeCurrentBatch: 0,
      decomposeTotalBatches: 0,
      allTasks: updatedTasks,
    );
    unawaited(_saveState(immediate: true));
  }

  // ========== Model Configuration ==========
  void setOutlineModel(NovelModelConfig? config) {
    if (_deferUntilLoaded(() => setOutlineModel(config))) return;
    state = state.copyWith(outlineModel: config);
    unawaited(_saveState());
  }

  void setOutlinePrompt(String prompt) {
    if (_deferUntilLoaded(() => setOutlinePrompt(prompt))) return;
    if (state.outlineModel != null) {
      state = state.copyWith(
          outlineModel: state.outlineModel!.copyWith(systemPrompt: prompt));
    } else {
      // Create a placeholder config to store the prompt even when no model is selected
      state = state.copyWith(
          outlineModel: NovelModelConfig(
              providerId: '', modelId: '', systemPrompt: prompt));
    }
    unawaited(_saveState());
  }

  void setDecomposeModel(NovelModelConfig? config) {
    if (_deferUntilLoaded(() => setDecomposeModel(config))) return;
    state = state.copyWith(decomposeModel: config);
    unawaited(_saveState());
  }

  void setDecomposePrompt(String prompt) {
    if (_deferUntilLoaded(() => setDecomposePrompt(prompt))) return;
    if (state.decomposeModel != null) {
      state = state.copyWith(
          decomposeModel: state.decomposeModel!.copyWith(systemPrompt: prompt));
    } else {
      state = state.copyWith(
          decomposeModel: NovelModelConfig(
              providerId: '', modelId: '', systemPrompt: prompt));
    }
    unawaited(_saveState());
  }

  void setWriterModel(NovelModelConfig? config) {
    if (_deferUntilLoaded(() => setWriterModel(config))) return;
    state = state.copyWith(writerModel: config);
    unawaited(_saveState());
  }

  void setWriterPrompt(String prompt) {
    if (_deferUntilLoaded(() => setWriterPrompt(prompt))) return;
    if (state.writerModel != null) {
      state = state.copyWith(
          writerModel: state.writerModel!.copyWith(systemPrompt: prompt));
    } else {
      state = state.copyWith(
          writerModel: NovelModelConfig(
              providerId: '', modelId: '', systemPrompt: prompt));
    }
    unawaited(_saveState());
  }

  void setReviewerModel(NovelModelConfig? config) {
    if (_deferUntilLoaded(() => setReviewerModel(config))) return;
    state = state.copyWith(reviewerModel: config);
    unawaited(_saveState());
  }

  void setReviewerPrompt(String prompt) {
    if (_deferUntilLoaded(() => setReviewerPrompt(prompt))) return;
    if (state.reviewerModel != null) {
      state = state.copyWith(
          reviewerModel: state.reviewerModel!.copyWith(systemPrompt: prompt));
    } else {
      state = state.copyWith(
          reviewerModel: NovelModelConfig(
              providerId: '', modelId: '', systemPrompt: prompt));
    }
    unawaited(_saveState());
  }

  // ========== Novel Prompt Presets ==========
  void setActivePromptPresetId(String? id) {
    if (_deferUntilLoaded(() => setActivePromptPresetId(id))) return;
    state = state.copyWith(activePromptPresetId: id);
    unawaited(_saveState());
  }

  void addPromptPreset(NovelPromptPreset preset) {
    if (_deferUntilLoaded(() => addPromptPreset(preset))) return;
    state = state.copyWith(
      promptPresets: [...state.promptPresets, preset],
      activePromptPresetId: preset.id,
    );
    unawaited(_saveState());
  }

  void updatePromptPreset(NovelPromptPreset preset) {
    if (_deferUntilLoaded(() => updatePromptPreset(preset))) return;
    final updatedPresets =
        state.promptPresets.map((p) => p.id == preset.id ? preset : p).toList();
    state = state.copyWith(
      promptPresets: updatedPresets,
      activePromptPresetId: preset.id,
    );
    unawaited(_saveState());
  }

  void deletePromptPreset(String presetId) {
    if (_deferUntilLoaded(() => deletePromptPreset(presetId))) return;
    state = state.copyWith(
      promptPresets:
          state.promptPresets.where((p) => p.id != presetId).toList(),
      activePromptPresetId: state.activePromptPresetId == presetId
          ? null
          : state.activePromptPresetId,
    );
    unawaited(_saveState());
  }

  // ========== Unlimited Mode ==========
  void setUnlimitedMode(bool enabled) {
    if (_deferUntilLoaded(() => setUnlimitedMode(enabled))) return;
    state = state.copyWith(isUnlimitedMode: enabled);
    unawaited(_saveState());
  }
}
