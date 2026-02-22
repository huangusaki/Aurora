// ignore_for_file: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member, unused_element

part of 'novel_provider.dart';

extension NovelNotifierWorkflowIo on NovelNotifier {
  Future<String?> _ensureProjectKnowledgeBase(String projectId) async {
    final project = state.projects.where((p) => p.id == projectId).firstOrNull;
    if (project == null) return null;

    final baseId = await _knowledgeStorage.ensureProjectBase(
      projectId: project.id,
      projectName: project.name,
      existingBaseId: project.knowledgeBaseId,
    );

    if (!state.projects.any((p) => p.id == projectId)) {
      await _knowledgeStorage.deleteProjectBase(projectId);
      return null;
    }

    if (project.knowledgeBaseId != baseId) {
      final updatedProjects = state.projects
          .map((p) =>
              p.id == project.id ? p.copyWith(knowledgeBaseId: baseId) : p)
          .toList();
      state = state.copyWith(projects: updatedProjects);
      _saveState();
    }
    return baseId;
  }

  Future<void> _ensureKnowledgeBaseBindingsForAllProjects() async {
    if (state.projects.isEmpty) return;

    var hasChanges = false;
    final updatedProjects = <NovelProject>[];

    for (final project in state.projects) {
      try {
        final baseId = await _knowledgeStorage.ensureProjectBase(
          projectId: project.id,
          projectName: project.name,
          existingBaseId: project.knowledgeBaseId,
        );
        if (project.knowledgeBaseId != baseId) {
          hasChanges = true;
          updatedProjects.add(project.copyWith(knowledgeBaseId: baseId));
        } else {
          updatedProjects.add(project);
        }
      } catch (_) {
        updatedProjects.add(project);
      }
    }

    if (hasChanges) {
      state = state.copyWith(projects: updatedProjects);
      await _saveState();
    }
  }

  Future<KnowledgeBaseSummary?> getSelectedProjectKnowledgeBaseSummary() async {
    await _waitUntilLoaded();
    final project = state.selectedProject;
    if (project == null) return null;

    final baseId = await _ensureProjectKnowledgeBase(project.id);
    if (baseId == null) return null;

    return _knowledgeStorage.loadBaseSummaryById(baseId);
  }

  Future<KnowledgeIngestReport?> importKnowledgeFilesForSelectedProject(
    List<String> filePaths,
  ) async {
    await _waitUntilLoaded();
    final project = state.selectedProject;
    if (project == null) return null;

    final baseId = await _ensureProjectKnowledgeBase(project.id);
    if (baseId == null || baseId.trim().isEmpty) {
      return null;
    }

    final settings = _ref.read(settingsProvider);
    final embeddingProvider = _resolveEmbeddingProvider(settings);

    return _knowledgeStorage.ingestFiles(
      baseId: baseId,
      filePaths: filePaths,
      useEmbedding: settings.knowledgeUseEmbedding,
      embeddingModel: settings.knowledgeEmbeddingModel,
      embeddingProvider: embeddingProvider,
    );
  }

  Future<File> get _stateFile async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'novel_writing_state.json'));
  }

  Future<void> loadState() async {
    try {
      final file = await _stateFile;
      if (await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        state = NovelWritingState.fromJson(json);

        // Fix stuck tasks: reset 'running', 'reviewing', or 'needsRevision' tasks to 'pending' on startup
        // since the workflow is not actually running after a restart
        final fixedTasks = state.allTasks.map((t) {
          if (t.status == TaskStatus.running ||
              t.status == TaskStatus.reviewing ||
              t.status == TaskStatus.needsRevision) {
            return t.copyWith(status: TaskStatus.pending, retryCount: 0);
          }
          return t;
        }).toList();

        if (state.allTasks.any((t) =>
                t.status == TaskStatus.running ||
                t.status == TaskStatus.reviewing ||
                t.status == TaskStatus.needsRevision) ||
            state.isDecomposing) {
          state = state.copyWith(
            allTasks: fixedTasks,
            isRunning: false,
            isPaused: false,
            isDecomposing: false,
            decomposeStatus: null,
            decomposeCurrentBatch: 0,
            decomposeTotalBatches: 0,
          );
          unawaited(_saveState(immediate: true));
        }
      }

      await _ensureKnowledgeBaseBindingsForAllProjects();
    } catch (e) {
      // Ignore load errors, start with empty state
    } finally {
      _isStateLoaded = true;
    }
  }

  Future<void> _enqueueSaveWrite(String payload) {
    _saveQueue = _saveQueue.then((_) async {
      try {
        final file = await _stateFile;
        await file.writeAsString(payload);
      } catch (_) {
        // Ignore save errors
      }
    });
    return _saveQueue;
  }

  Future<void> _flushPendingSave() async {
    final completer = _pendingSaveCompleter;
    _pendingSaveCompleter = null;
    final payload = jsonEncode(state.toJson());
    await _enqueueSaveWrite(payload);
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  Future<void> _saveState({bool immediate = false}) {
    if (immediate) {
      _saveDebounceTimer?.cancel();
      return _flushPendingSave();
    }

    if (_pendingSaveCompleter == null || _pendingSaveCompleter!.isCompleted) {
      _pendingSaveCompleter = Completer<void>();
    }

    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(milliseconds: 250), () {
      unawaited(_flushPendingSave());
    });
    return _pendingSaveCompleter!.future;
  }

  // ========== LLM Call Helper ==========
  Future<String> _callLLM(
      NovelModelConfig config, String systemPrompt, String userMessage,
      {CancelToken? cancelToken}) async {
    if (!_isUsableModelConfig(config)) {
      throw Exception('Model not configured');
    }

    final settings = _ref.read(settingsProvider);

    // Find the provider config
    final provider = settings.providers.firstWhere(
      (p) => p.id == config.providerId,
      orElse: () => settings.activeProvider,
    );

    // Create a temporary settings state with the selected model
    final tempSettings = settings.copyWith(
      activeProviderId: provider.id,
    );

    // Update the provider's selected model temporarily
    final updatedProvider = provider.copyWith(selectedModel: config.modelId);
    final updatedProviders = tempSettings.providers.map((p) {
      return p.id == updatedProvider.id ? updatedProvider : p;
    }).toList();

    final finalSettings = tempSettings.copyWith(providers: updatedProviders);

    final llmService = ModelRoutedLlmService(finalSettings);

    final messages = [
      Message(
        id: const Uuid().v4(),
        content: systemPrompt,
        isUser: false,
        timestamp: DateTime.now(),
        role: 'system',
      ),
      Message.user(userMessage),
    ];

    int attempts = 0;
    const maxAttempts = 3;

    while (true) {
      attempts++;
      final requestStartTime = DateTime.now();

      try {
        final response =
            await llmService.getResponse(messages, cancelToken: cancelToken);
        final durationMs =
            DateTime.now().difference(requestStartTime).inMilliseconds;

        // Check for truncation (Content Filter)
        final isTruncated = response.finishReason == 'prohibited_content' ||
            response.finishReason == 'content_filter';

        if (isTruncated) {
          debugPrint(
              '[NOVEL][WARN] LLM request truncated (reason: ${response.finishReason}); retrying ($attempts/$maxAttempts).');

          // Still track usage since tokens were consumed
          _ref.read(usageStatsProvider.notifier).incrementUsage(
                config.modelId,
                success: true,
                durationMs: durationMs,
                tokenCount: response.usage ?? 0,
              );

          if (attempts < maxAttempts) {
            continue; // Retry loop
          } else {
            throw Exception(
                'Generation stopped due to ${response.finishReason} (Max retries reached)');
          }
        }

        // Success case
        _ref.read(usageStatsProvider.notifier).incrementUsage(
              config.modelId,
              success: true,
              durationMs: durationMs,
              tokenCount: response.usage ?? 0,
            );

        return response.content ?? '';
      } catch (e) {
        if (e is DioException && e.type == DioExceptionType.cancel) {
          rethrow;
        }

        // Track failed usage
        final durationMs =
            DateTime.now().difference(requestStartTime).inMilliseconds;
        AppErrorType errorType = AppErrorType.unknown;
        if (e is AppException) {
          errorType = e.type;
        }
        _ref.read(usageStatsProvider.notifier).incrementUsage(
              config.modelId,
              success: false,
              durationMs: durationMs,
              errorType: errorType,
            );
        rethrow;
      }
    }
  }

  // ========== Workflow Engine ==========
  Future<void> runWorkflow() async {
    await _waitUntilLoaded();
    if (state.isRunning) return;

    _currentCancelToken?.cancel('Starting new workflow');
    _currentCancelToken = CancelToken();
    _shouldStop = false;
    state = state.copyWith(isRunning: true, isPaused: false);
    unawaited(_saveState());

    await _processTaskQueue();
  }

  Future<void> _processTaskQueue() async {
    while (!_shouldStop && mounted) {
      // Find next pending task for current project
      // We look for tasks that are 'pending' OR 'needsRevision' (if we want to auto-retry those,
      // though typically they transition back to 'reviewing' immediately)
      final allTasks = state.allTasks;
      final pendingTask = allTasks.firstWhere(
        (t) =>
            (t.status == TaskStatus.pending || t.status == TaskStatus.failed) &&
            _isTaskInCurrentProject(t),
        orElse: () => NovelTask(id: '', chapterId: '', description: ''),
      );

      if (pendingTask.id.isEmpty) {
        // No more pending tasks
        debugPrint('[NOVEL][INFO] No more pending tasks; stopping loop.');
        state = state.copyWith(isRunning: false);
        _currentCancelToken = null;
        unawaited(_saveState());
        return;
      }

      // Check if paused
      while (state.isPaused && !_shouldStop) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (_shouldStop) {
        debugPrint('[NOVEL][INFO] Workflow stopped by _shouldStop flag.');
        break;
      }

      // Execute the task
      await _executeTask(pendingTask.id);

      // Safety: wait a tiny bit to ensure state updates propagate
      await Future.delayed(const Duration(milliseconds: 50));
    }

    state = state.copyWith(isRunning: false);
    _currentCancelToken = null;
    unawaited(_saveState());
  }

  bool _isTaskInCurrentProject(NovelTask task) {
    final selectedProjectId = state.selectedProjectId;
    if (selectedProjectId == null) return false;
    return _isTaskInProject(task, selectedProjectId);
  }

  bool _isTaskInProject(NovelTask task, String projectId) {
    final project = state.projects.where((p) => p.id == projectId).firstOrNull;
    if (project == null) return false;
    return project.chapters.any((c) => c.id == task.chapterId);
  }

  Future<void> _executeTask(String taskId) async {
    // Mark task as running and reset its internal retry state
    final updatedTasks = state.allTasks.map((t) {
      if (t.id == taskId) {
        return t.copyWith(
          status: TaskStatus.running,
          retryCount: 0,
          reviewFeedback: '',
        );
      }
      return t;
    }).toList();
    state = state.copyWith(allTasks: updatedTasks);

    final task = state.allTasks.firstWhere((t) => t.id == taskId);

    try {
      // Use writer model to execute the task
      final writerConfig = state.writerModel;
      if (!_isUsableModelConfig(writerConfig)) {
        throw Exception('Writer model not configured');
      }
      final activeWriterConfig = writerConfig!;

      final baseSystemPrompt = activeWriterConfig.systemPrompt.isNotEmpty
          ? activeWriterConfig.systemPrompt
          : NovelPromptPresets.writerBase;

      final systemPrompt = state.isUnlimitedMode
          ? '${NovelPromptPresets.writerUnlimitedPrefix}\n$baseSystemPrompt'
          : baseSystemPrompt;

      // Build context from all chapters in the project (outlines only, not full content)
      final allChapters = state.selectedProject?.chapters ?? [];
      final currentChapterIndex =
          allChapters.indexWhere((c) => c.id == task.chapterId);

      // Get chapter title for context
      final chapter =
          currentChapterIndex >= 0 ? allChapters[currentChapterIndex] : null;
      final chapterTitle = chapter?.title ?? '未知章节';
      final projectName = state.selectedProject?.name ?? '未知项目';
      final worldContext =
          state.selectedProject?.worldContext ?? const WorldContext();

      // ========== Step 1: Context Agent - 智能筛选上下文 ==========
      // 使用大纲模型（或降级到写作模型）进行上下文筛选
      final contextModel = _isUsableModelConfig(state.outlineModel)
          ? state.outlineModel!
          : activeWriterConfig;
      final filteredContextStr = await _buildFilteredContext(
        contextModel,
        task.description,
        chapterTitle,
        worldContext,
        cancelToken: _currentCancelToken,
      );
      final projectKnowledgeContext = await _buildProjectKnowledgeContext(
        taskDescription: task.description,
        chapterTitle: chapterTitle,
      );

      final StringBuffer contextBuffer = StringBuffer();

      // Add project info
      contextBuffer.writeln('【项目】$projectName');
      contextBuffer.writeln();

      // Add filtered world context (smart selection)
      if (filteredContextStr.isNotEmpty) {
        contextBuffer.writeln(filteredContextStr);
      }

      // Add project-dedicated knowledge base context.
      if (projectKnowledgeContext.isNotEmpty) {
        contextBuffer.writeln(projectKnowledgeContext);
        contextBuffer.writeln();
      }

      // Add analyzed writing style reference
      final analyzedStyle = state.selectedProject?.analyzedStyle;
      if (analyzedStyle != null && analyzedStyle.trim().isNotEmpty) {
        contextBuffer.writeln('【文风参考】⭐请模仿以下文风特征进行写作：');
        contextBuffer.writeln(analyzedStyle);
        contextBuffer.writeln();
      }

      // Add outline of all chapters (descriptions only, not full content)
      if (allChapters.length > 1) {
        contextBuffer.writeln('【全书大纲】');
        for (int i = 0; i < allChapters.length; i++) {
          final c = allChapters[i];
          final tasks = state.tasksForChapter(c.id);
          final taskDesc = tasks.isNotEmpty ? tasks.first.description : '';
          final marker = c.id == task.chapterId ? '→' : ' ';
          contextBuffer.writeln('$marker ${c.title}: $taskDesc');
        }
        contextBuffer.writeln();
      }

      // Add recent chapter summaries (if available)
      final recentSummaries = _getRecentChapterSummaries(task.chapterId, 3);
      if (recentSummaries.isNotEmpty) {
        contextBuffer.writeln('【前情提要】');
        contextBuffer.writeln(recentSummaries);
        contextBuffer.writeln();
      }

      // Add previous chapter full content for cohesion (避免情节重复和跳变)
      final prevChapterContent = _getPreviousChapterContent(task.chapterId);
      if (prevChapterContent.isNotEmpty) {
        contextBuffer.writeln('【上一章完整内容】⚠️重要：请仔细阅读，确保剧情连贯衔接，避免重复已写过的情节');
        contextBuffer.writeln(prevChapterContent);
        contextBuffer.writeln();
      }

      // Add current chapter info
      contextBuffer.writeln('【当前章节】$chapterTitle');
      contextBuffer.writeln();

      // Add current task requirement
      contextBuffer.writeln('【本章要求】');
      contextBuffer.writeln(task.description);
      contextBuffer.writeln();
      contextBuffer.writeln('请根据以上大纲和本章要求，写出本章完整正文（2000-5000字）。');

      final String fullPrompt = contextBuffer.toString();

      // ========== Step 2: Writer - 写作 ==========
      final result = await _callLLM(
          activeWriterConfig, systemPrompt, fullPrompt,
          cancelToken: _currentCancelToken);

      if (_shouldStop) return; // Stop if requested

      // Update task with content
      final updatedTasks = state.allTasks.map((t) {
        if (t.id == taskId) {
          return t.copyWith(
              content: result,
              status: state.isReviewEnabled
                  ? TaskStatus.reviewing
                  : TaskStatus.success);
        }
        return t;
      }).toList();
      state = state.copyWith(allTasks: updatedTasks);
      _saveState();

      // 保存写作上下文（用于审查失败时的修订）
      final writingContextForRevision =
          contextBuffer.toString().split('请根据以上大纲和本章要求')[0];

      // If review is enabled, run the review (extraction happens after review passes)
      if (state.isReviewEnabled && !_shouldStop) {
        await _reviewTask(taskId, result,
            writingContext: writingContextForRevision);
      } else {
        // Review not enabled, extract context updates directly
        await _extractContextUpdates(result);
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        // 静默处理中止
        debugPrint('[NOVEL][INFO] Task $taskId execution cancelled by user.');
        return;
      }
      _updateTaskStatus(taskId, TaskStatus.failed);
      // Store error in reviewFeedback field
      final updatedTasks = state.allTasks.map((t) {
        if (t.id == taskId) {
          return t.copyWith(reviewFeedback: 'Error: $e');
        }
        return t;
      }).toList();
      state = state.copyWith(allTasks: updatedTasks);
      _saveState();
    }
  }

  Future<String> _buildProjectKnowledgeContext({
    required String taskDescription,
    required String chapterTitle,
  }) async {
    final project = state.selectedProject;
    if (project == null) return '';

    final baseId = await _ensureProjectKnowledgeBase(project.id);
    if (baseId == null || baseId.trim().isEmpty) return '';

    final settings = _ref.read(settingsProvider);
    final embeddingProvider = settings.knowledgeUseEmbedding
        ? _resolveEmbeddingProvider(settings)
        : null;

    final retrievalQuery = '$chapterTitle\n$taskDescription'.trim();
    if (retrievalQuery.isEmpty) return '';

    try {
      final kbResult = await _knowledgeStorage.retrieveContext(
        query: retrievalQuery,
        baseIds: [baseId],
        topK: settings.knowledgeTopK,
        useEmbedding: settings.knowledgeUseEmbedding,
        embeddingModel: settings.knowledgeEmbeddingModel,
        embeddingProvider: embeddingProvider,
        requiredScope: KnowledgeBaseScope.studioProject,
        requiredProjectId: project.id,
      );

      if (!kbResult.hasContext) return '';

      final buffer = StringBuffer();
      buffer.writeln('【项目知识库】');
      buffer.writeln('以下内容来自当前项目专用知识库，只在相关时引用。');
      buffer.writeln();

      for (int i = 0; i < kbResult.chunks.length; i++) {
        final item = kbResult.chunks[i];
        buffer.writeln('[P-KB${i + 1}] ${item.sourceLabel}');
        buffer.writeln(item.text);
        buffer.writeln();
      }

      buffer.writeln('如资料不足，请明确说明，不要凭空补全。');
      return buffer.toString().trim();
    } catch (_) {
      return '';
    }
  }

  /// Context Agent: 智能筛选本章需要的上下文
  Future<String> _buildFilteredContext(
    NovelModelConfig config,
    String taskDescription,
    String chapterTitle,
    WorldContext worldContext, {
    CancelToken? cancelToken,
  }) async {
    // 如果设定很少（少于10项），直接全量返回，不需要筛选
    final totalItems = worldContext.characters.length +
        worldContext.locations.length +
        worldContext.rules.length +
        worldContext.relationships.length;
    if (totalItems < 10) {
      return worldContext.toPromptString();
    }

    try {
      // 构建可用的 keys 列表
      final availableKeys = StringBuffer();
      availableKeys.writeln('可用角色: ${worldContext.characters.keys.join(", ")}');
      availableKeys.writeln('可用地点: ${worldContext.locations.keys.join(", ")}');
      availableKeys.writeln('可用规则: ${worldContext.rules.keys.join(", ")}');
      availableKeys
          .writeln('可用关系: ${worldContext.relationships.keys.join(", ")}');

      final prompt = '''本章任务：$taskDescription
章节标题：$chapterTitle

${availableKeys.toString()}

请分析本章需要哪些设定信息。''';

      final result = await _callLLM(
          config, NovelPromptPresets.contextBuilder, prompt,
          cancelToken: cancelToken);
      final selection = jsonDecode(result) as Map<String, dynamic>;

      // 根据筛选结果，构建精简的上下文
      final buffer = StringBuffer();

      // 筛选角色
      final neededCharacters =
          List<String>.from(selection['neededCharacters'] ?? []);
      if (neededCharacters.isNotEmpty && worldContext.includeCharacters) {
        buffer.writeln('【相关人物】');
        for (final charName in neededCharacters) {
          if (worldContext.characters.containsKey(charName)) {
            buffer.writeln('- $charName: ${worldContext.characters[charName]}');
          }
        }
        buffer.writeln();
      }

      // 筛选地点
      final neededLocations =
          List<String>.from(selection['neededLocations'] ?? []);
      if (neededLocations.isNotEmpty && worldContext.includeLocations) {
        buffer.writeln('【相关场景】');
        for (final locName in neededLocations) {
          if (worldContext.locations.containsKey(locName)) {
            buffer.writeln('- $locName: ${worldContext.locations[locName]}');
          }
        }
        buffer.writeln();
      }

      // 筛选规则
      final neededRules = List<String>.from(selection['neededRules'] ?? []);
      if (neededRules.isNotEmpty && worldContext.includeRules) {
        buffer.writeln('【相关规则】');
        for (final ruleName in neededRules) {
          if (worldContext.rules.containsKey(ruleName)) {
            buffer.writeln('- $ruleName: ${worldContext.rules[ruleName]}');
          }
        }
        buffer.writeln();
      }

      // 筛选关系
      final neededRelationships =
          List<String>.from(selection['neededRelationships'] ?? []);
      if (neededRelationships.isNotEmpty && worldContext.includeRelationships) {
        buffer.writeln('【相关关系】');
        for (final relKey in neededRelationships) {
          if (worldContext.relationships.containsKey(relKey)) {
            buffer.writeln('- $relKey: ${worldContext.relationships[relKey]}');
          }
        }
        buffer.writeln();
      }

      // 伏笔总是全量包含（通常不多）
      if (worldContext.includeForeshadowing &&
          worldContext.foreshadowing.isNotEmpty) {
        buffer.writeln('【伏笔/线索】');
        for (final f in worldContext.foreshadowing) {
          buffer.writeln('- $f');
        }
        buffer.writeln();
      }

      return buffer.toString();
    } catch (e) {
      // 如果筛选失败，降级为全量返回
      return worldContext.toPromptString();
    }
  }

  /// 获取最近几章的摘要（用于前情提要）
  String _getRecentChapterSummaries(String currentChapterId, int count) {
    final project = state.selectedProject;
    if (project == null) return '';

    final currentIndex =
        project.chapters.indexWhere((c) => c.id == currentChapterId);
    if (currentIndex <= 0) return '';

    final buffer = StringBuffer();
    final startIndex = (currentIndex - count).clamp(0, currentIndex);

    for (int i = startIndex; i < currentIndex; i++) {
      final chapter = project.chapters[i];
      final tasks = state.tasksForChapter(chapter.id);

      // 查找该章节的摘要（如果有的话，从 task 内容中提取）
      for (final task in tasks) {
        if (task.status == TaskStatus.success && task.content != null) {
          // 取前100个字符作为简要摘要
          final preview = task.content!.length > 100
              ? '${task.content!.substring(0, 100)}...'
              : task.content!;
          buffer.writeln('${chapter.title}: $preview');
          break;
        }
      }
    }

    return buffer.toString();
  }

  /// 获取上一章的完整内容（用于剧情衔接，避免重复和跳变）
  String _getPreviousChapterContent(String currentChapterId) {
    final project = state.selectedProject;
    if (project == null) return '';

    final currentIndex =
        project.chapters.indexWhere((c) => c.id == currentChapterId);
    if (currentIndex <= 0) return '';

    final prevChapter = project.chapters[currentIndex - 1];
    final tasks = state.tasksForChapter(prevChapter.id);

    // 查找上一章的生成内容
    for (final task in tasks) {
      if (task.status == TaskStatus.success &&
          task.content != null &&
          task.content!.isNotEmpty) {
        String content = task.content!;
        // 去除章节摘要部分（--- 后的内容），只保留正文
        final summaryIndex = content.indexOf('\n---\n');
        if (summaryIndex > 0) {
          content = content.substring(0, summaryIndex).trim();
        }
        return content;
      }
    }

    return '';
  }

  String exportChapterContent(String chapterId) {
    final tasks = state.tasksForChapter(chapterId);
    final buffer = StringBuffer();

    // Find chapter title
    final chapter = state.selectedProject?.chapters.firstWhere(
      (c) => c.id == chapterId,
      orElse: () => NovelChapter(id: '', title: 'Unknown Chapter', order: 0),
    );

    if (chapter != null) {
      buffer.writeln('# ${chapter.title}');
      buffer.writeln();
    }

    for (final task in tasks) {
      if (task.status == TaskStatus.success && task.content != null) {
        buffer.writeln(task.content);
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  /// 导出全书内容（所有章节）
  String exportFullNovel() {
    final project = state.selectedProject;
    if (project == null) return '';

    final buffer = StringBuffer();

    // 添加书名
    buffer.writeln('# ${project.name}');
    buffer.writeln();

    // 按顺序导出每个章节
    for (final chapter in project.chapters) {
      final chapterContent = exportChapterContent(chapter.id);
      if (chapterContent.isNotEmpty) {
        buffer.writeln(chapterContent);
        buffer.writeln('---'); // 章节分隔符
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  /// 获取全书统计信息
  Map<String, dynamic> getNovelStats() {
    final project = state.selectedProject;
    if (project == null) return {};

    int totalChapters = project.chapters.length;
    int completedChapters = 0;
    int totalWords = 0;

    for (final chapter in project.chapters) {
      final tasks = state.tasksForChapter(chapter.id);
      bool hasContent = false;
      for (final task in tasks) {
        if (task.status == TaskStatus.success && task.content != null) {
          hasContent = true;
          totalWords += StringUtils.countWords(task.content!);
        }
      }
      if (hasContent) completedChapters++;
    }

    return {
      'totalChapters': totalChapters,
      'completedChapters': completedChapters,
      'totalWords': totalWords,
    };
  }

  Future<void> _reviewTask(String taskId, String content,
      {String writingContext = ''}) async {
    final reviewerConfig = state.reviewerModel;
    if (!_isUsableModelConfig(reviewerConfig)) {
      // No reviewer configured, auto-approve and reset retry count
      final updatedTasks = state.allTasks.map((t) {
        if (t.id == taskId) {
          return t.copyWith(status: TaskStatus.success, retryCount: 0);
        }
        return t;
      }).toList();
      state = state.copyWith(allTasks: updatedTasks);
      unawaited(_saveState());
      await _extractContextUpdates(content);
      return;
    }

    final task = state.allTasks.firstWhere((t) => t.id == taskId);

    try {
      final activeReviewerConfig = reviewerConfig!;
      final systemPrompt = activeReviewerConfig.systemPrompt.isNotEmpty
          ? activeReviewerConfig.systemPrompt
          : NovelPromptPresets.reviewer;

      final actualWordCount = StringUtils.countWords(content);
      final reviewPrompt = '''
任务描述: ${task.description}

当前内容字数统计（不要质疑这个结果，不需要额外计算）: $actualWordCount

生成的内容:
$content

请审查以上内容。''';

      final reviewResult = await _callLLM(
          activeReviewerConfig, systemPrompt, reviewPrompt,
          cancelToken: _currentCancelToken);

      if (_shouldStop) return; // Stop if requested

      // Strip markdown code blocks if present (```json ... ```)
      String jsonStr = reviewResult.trim();
      if (jsonStr.startsWith('```')) {
        // Remove opening ``` or ```json
        final firstNewline = jsonStr.indexOf('\n');
        if (firstNewline > 0) {
          jsonStr = jsonStr.substring(firstNewline + 1);
        }
        // Remove closing ```
        if (jsonStr.endsWith('```')) {
          jsonStr = jsonStr.substring(0, jsonStr.length - 3).trim();
        }
      }

      // Try to parse review result
      try {
        final reviewJson = jsonDecode(jsonStr) as Map<String, dynamic>;

        // approved 字段必须存在且为 bool，否则视为格式错误
        if (!reviewJson.containsKey('approved') ||
            reviewJson['approved'] is! bool) {
          throw FormatException(
              'Missing or invalid "approved" field in review result');
        }
        final approved = reviewJson['approved'] as bool;

        if (approved) {
          // ✅ 审查通过 → success
          final updatedTasks = state.allTasks.map((t) {
            if (t.id == taskId) {
              return t.copyWith(
                status: TaskStatus.success,
                content: content,
                reviewFeedback: reviewResult,
                retryCount: 0, // Reset retry count on success
              );
            }
            return t;
          }).toList();
          state = state.copyWith(allTasks: updatedTasks);
          _saveState();

          // 审查通过后：提取伏笔和人物信息变化
          await _extractContextUpdates(content);
        } else {
          // ❌ 审查不通过
          final currentRetryCount = task.retryCount;

          if (currentRetryCount == 0) {
            // 第一次失败 → needsRevision，进行修订
            final issues = reviewJson['issues'] as List<dynamic>? ?? [];
            final suggestions = reviewJson['suggestions'] as String? ?? '';

            // 更新状态为 needsRevision
            final updatedTasks = state.allTasks.map((t) {
              if (t.id == taskId) {
                return t.copyWith(
                  status: TaskStatus.needsRevision,
                  reviewFeedback: '第1次审查未通过，正在修订...\n$reviewResult',
                  retryCount: 1,
                );
              }
              return t;
            }).toList();
            state = state.copyWith(allTasks: updatedTasks);
            _saveState();

            // 调用修订
            final revisedContent = await _reviseContent(
                content, issues, suggestions, task.description, writingContext,
                cancelToken: _currentCancelToken);

            if (_shouldStop) return;

            // 更新状态为 reviewing 并重新审查
            _updateTaskStatus(taskId, TaskStatus.reviewing);
            await _reviewTask(taskId, revisedContent,
                writingContext: writingContext);
            return; // 递归调用结束后直接返回，避免执行后续逻辑
          } else {
            // 第二次失败 → failed，停止队列
            final updatedTasks = state.allTasks.map((t) {
              if (t.id == taskId) {
                return t.copyWith(
                  status: TaskStatus.failed,
                  content: content,
                  reviewFeedback: '审查失败（连续2次未通过）\n$reviewResult',
                  retryCount: currentRetryCount + 1,
                );
              }
              return t;
            }).toList();
            state = state.copyWith(allTasks: updatedTasks);
            _saveState();

            // 停止后续任务执行，等待人工处理
            _shouldStop = true;
            return;
          }
        }
      } catch (e) {
        // Review result is not valid JSON, mark as error
        debugPrint('[NOVEL][WARN] Review JSON parse error: $e');
        debugPrint('[NOVEL][WARN] Raw review result: $reviewResult');
        final updatedTasks = state.allTasks.map((t) {
          if (t.id == taskId) {
            return t.copyWith(
              status: TaskStatus.failed,
              reviewFeedback: '审查结果解析失败\n$reviewResult',
            );
          }
          return t;
        }).toList();
        state = state.copyWith(allTasks: updatedTasks);
        _saveState();
        _shouldStop = true;
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        debugPrint('[NOVEL][INFO] Task $taskId review cancelled by user.');
        return;
      }
      // Review failed, mark task as failed and needing attention
      final updatedTasks = state.allTasks.map((t) {
        if (t.id == taskId) {
          return t.copyWith(
            status: TaskStatus.failed,
            reviewFeedback: 'Review error: $e',
          );
        }
        return t;
      }).toList();
      state = state.copyWith(allTasks: updatedTasks);
      _saveState();
    }
  }

  /// 根据审查意见修订内容
  Future<String> _reviseContent(
    String originalContent,
    List<dynamic> issues,
    String suggestions,
    String taskDescription,
    String writingContext, {
    CancelToken? cancelToken,
  }) async {
    final writerConfig = state.writerModel;
    if (!_isUsableModelConfig(writerConfig)) {
      return originalContent; // 无法修订，返回原内容
    }
    final activeWriterConfig = writerConfig!;

    // 构建问题列表
    final issuesList = StringBuffer();
    for (int i = 0; i < issues.length; i++) {
      final issue = issues[i] as Map<String, dynamic>;
      final severity = issue['severity'] ?? 'medium';
      final type = issue['type'] ?? 'unknown';
      final desc = issue['description'] ?? '';
      issuesList.writeln('${i + 1}. [$severity] $type: $desc');
    }

    final revisionPrompt = '''【写作约束】（修订时必须遵守）
$writingContext

【本章任务】
$taskDescription

【原始章节内容】
$originalContent

【审查发现的问题】
${issuesList.toString()}

【改进建议】
$suggestions

请根据以上审查意见修改章节内容。
- 必须严格遵守【写作约束】中的设定
- 不可编造约束中没有的角色、能力、事件
- 只输出修改后的完整章节正文''';

    try {
      final revisedContent = await _callLLM(
          activeWriterConfig, NovelPromptPresets.reviser, revisionPrompt,
          cancelToken: cancelToken);
      return revisedContent;
    } catch (e) {
      return originalContent; // 修订失败，返回原内容
    }
  }

  void _updateTaskStatus(String taskId, TaskStatus status) {
    if (_deferUntilLoaded(() => _updateTaskStatus(taskId, status))) return;
    final updatedTasks = state.allTasks.map((t) {
      return t.id == taskId ? t.copyWith(status: status) : t;
    }).toList();
    state = state.copyWith(allTasks: updatedTasks);
    unawaited(_saveState());
  }
}
