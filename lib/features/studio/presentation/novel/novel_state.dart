import 'package:uuid/uuid.dart';

/// Sentinel value for copyWith to distinguish between "not provided" and "explicitly null"
const _sentinel = Object();

enum TaskStatus {
  pending,
  decomposing,
  running,
  reviewing,
  needsRevision, // Failed review once, will retry
  success,
  failed,
  paused,
}

class NovelModelConfig {
  final String providerId;
  final String modelId;
  final String systemPrompt;

  const NovelModelConfig({
    required this.providerId,
    required this.modelId,
    this.systemPrompt = '',
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NovelModelConfig &&
        other.providerId == providerId &&
        other.modelId == modelId;
  }

  @override
  int get hashCode => Object.hash(providerId, modelId);

  NovelModelConfig copyWith({
    String? providerId,
    String? modelId,
    String? systemPrompt,
  }) {
    return NovelModelConfig(
      providerId: providerId ?? this.providerId,
      modelId: modelId ?? this.modelId,
      systemPrompt: systemPrompt ?? this.systemPrompt,
    );
  }

  Map<String, dynamic> toJson() => {
        'providerId': providerId,
        'modelId': modelId,
        'systemPrompt': systemPrompt,
      };

  factory NovelModelConfig.fromJson(Map<String, dynamic> json) =>
      NovelModelConfig(
        providerId: json['providerId'] as String,
        modelId: json['modelId'] as String,
        systemPrompt: json['systemPrompt'] as String? ?? '',
      );
}

/// Novel-specific prompt preset (contains prompts for all 4 roles)
class NovelPromptPreset {
  final String id;
  final String name;
  final String outlinePrompt;
  final String decomposePrompt;
  final String writerPrompt;
  final String reviewerPrompt;

  const NovelPromptPreset({
    required this.id,
    required this.name,
    this.outlinePrompt = '',
    this.decomposePrompt = '',
    this.writerPrompt = '',
    this.reviewerPrompt = '',
  });

  factory NovelPromptPreset.create({
    required String name,
    required String outlinePrompt,
    required String decomposePrompt,
    required String writerPrompt,
    required String reviewerPrompt,
  }) {
    return NovelPromptPreset(
      id: const Uuid().v4(),
      name: name,
      outlinePrompt: outlinePrompt,
      decomposePrompt: decomposePrompt,
      writerPrompt: writerPrompt,
      reviewerPrompt: reviewerPrompt,
    );
  }

  NovelPromptPreset copyWith({
    String? id,
    String? name,
    String? outlinePrompt,
    String? decomposePrompt,
    String? writerPrompt,
    String? reviewerPrompt,
  }) {
    return NovelPromptPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      outlinePrompt: outlinePrompt ?? this.outlinePrompt,
      decomposePrompt: decomposePrompt ?? this.decomposePrompt,
      writerPrompt: writerPrompt ?? this.writerPrompt,
      reviewerPrompt: reviewerPrompt ?? this.reviewerPrompt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'outlinePrompt': outlinePrompt,
        'decomposePrompt': decomposePrompt,
        'writerPrompt': writerPrompt,
        'reviewerPrompt': reviewerPrompt,
      };

  factory NovelPromptPreset.fromJson(Map<String, dynamic> json) =>
      NovelPromptPreset(
        id: json['id'] as String,
        name: json['name'] as String,
        outlinePrompt: json['outlinePrompt'] as String? ?? '',
        decomposePrompt: json['decomposePrompt'] as String? ?? '',
        writerPrompt: json['writerPrompt'] as String? ?? '',
        reviewerPrompt: json['reviewerPrompt'] as String? ?? '',
      );
}

class NovelTask {
  final String id;
  final String chapterId;
  final String description;
  final TaskStatus status;
  final String? content;
  final String? reviewFeedback;
  final int retryCount; // Track how many times this task has been retried

  const NovelTask({
    required this.id,
    required this.chapterId,
    required this.description,
    this.status = TaskStatus.pending,
    this.content,
    this.reviewFeedback,
    this.retryCount = 0,
  });

  NovelTask copyWith({
    String? id,
    String? chapterId,
    String? description,
    TaskStatus? status,
    Object? content = _sentinel,
    Object? reviewFeedback = _sentinel,
    int? retryCount,
  }) {
    return NovelTask(
      id: id ?? this.id,
      chapterId: chapterId ?? this.chapterId,
      description: description ?? this.description,
      status: status ?? this.status,
      content: content == _sentinel ? this.content : content as String?,
      reviewFeedback: reviewFeedback == _sentinel
          ? this.reviewFeedback
          : reviewFeedback as String?,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'chapterId': chapterId,
        'description': description,
        'status': status.name,
        'content': content,
        'reviewFeedback': reviewFeedback,
        'retryCount': retryCount,
      };

  factory NovelTask.fromJson(Map<String, dynamic> json) => NovelTask(
        id: json['id'] as String,
        chapterId: json['chapterId'] as String,
        description: json['description'] as String,
        status: TaskStatus.values.firstWhere((e) => e.name == json['status'],
            orElse: () => TaskStatus.pending),
        content: json['content'] as String?,
        reviewFeedback: json['reviewFeedback'] as String?,
        retryCount: json['retryCount'] as int? ?? 0,
      );
}

class NovelChapter {
  final String id;
  final String title;
  final int order;

  const NovelChapter({
    required this.id,
    required this.title,
    this.order = 0,
  });

  NovelChapter copyWith({String? id, String? title, int? order}) {
    return NovelChapter(
      id: id ?? this.id,
      title: title ?? this.title,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'order': order};

  factory NovelChapter.fromJson(Map<String, dynamic> json) => NovelChapter(
        id: json['id'] as String,
        title: json['title'] as String,
        order: json['order'] as int? ?? 0,
      );
}

/// Dynamic world context that evolves with the story
class WorldContext {
  final Map<String, String> characters; // name -> description/status
  final Map<String, String> relationships; // "A->B" -> relationship description
  final Map<String, String> locations; // name -> description
  final List<String> foreshadowing; // active plot threads/foreshadowing
  final Map<String, String> rules; // world rules/magic systems
  final bool includeCharacters;
  final bool includeRelationships;
  final bool includeLocations;
  final bool includeForeshadowing;
  final bool includeRules;

  const WorldContext({
    this.characters = const {},
    this.relationships = const {},
    this.locations = const {},
    this.foreshadowing = const [],
    this.rules = const {},
    this.includeCharacters = true,
    this.includeRelationships = true,
    this.includeLocations = true,
    this.includeForeshadowing = true,
    this.includeRules = true,
  });

  WorldContext copyWith({
    Map<String, String>? characters,
    Map<String, String>? relationships,
    Map<String, String>? locations,
    List<String>? foreshadowing,
    Map<String, String>? rules,
    bool? includeCharacters,
    bool? includeRelationships,
    bool? includeLocations,
    bool? includeForeshadowing,
    bool? includeRules,
  }) {
    return WorldContext(
      characters: characters ?? this.characters,
      relationships: relationships ?? this.relationships,
      locations: locations ?? this.locations,
      foreshadowing: foreshadowing ?? this.foreshadowing,
      rules: rules ?? this.rules,
      includeCharacters: includeCharacters ?? this.includeCharacters,
      includeRelationships: includeRelationships ?? this.includeRelationships,
      includeLocations: includeLocations ?? this.includeLocations,
      includeForeshadowing: includeForeshadowing ?? this.includeForeshadowing,
      includeRules: includeRules ?? this.includeRules,
    );
  }

  Map<String, dynamic> toJson() => {
        'characters': characters,
        'relationships': relationships,
        'locations': locations,
        'foreshadowing': foreshadowing,
        'rules': rules,
        'includeCharacters': includeCharacters,
        'includeRelationships': includeRelationships,
        'includeLocations': includeLocations,
        'includeForeshadowing': includeForeshadowing,
        'includeRules': includeRules,
      };

  factory WorldContext.fromJson(Map<String, dynamic> json) => WorldContext(
        characters: Map<String, String>.from(json['characters'] as Map? ?? {}),
        relationships:
            Map<String, String>.from(json['relationships'] as Map? ?? {}),
        locations: Map<String, String>.from(json['locations'] as Map? ?? {}),
        foreshadowing: List<String>.from(json['foreshadowing'] as List? ?? []),
        rules: Map<String, String>.from(json['rules'] as Map? ?? {}),
        includeCharacters: json['includeCharacters'] as bool? ?? true,
        includeRelationships: json['includeRelationships'] as bool? ?? true,
        includeLocations: json['includeLocations'] as bool? ?? true,
        includeForeshadowing: json['includeForeshadowing'] as bool? ?? true,
        includeRules: json['includeRules'] as bool? ?? true,
      );

  /// Format context for LLM prompt
  String toPromptString() {
    final buffer = StringBuffer();

    if (includeRules && rules.isNotEmpty) {
      buffer.writeln('【世界规则】');
      rules.forEach((k, v) => buffer.writeln('- $k: $v'));
      buffer.writeln();
    }

    if (includeCharacters && characters.isNotEmpty) {
      buffer.writeln('【人物设定】');
      characters.forEach((k, v) => buffer.writeln('- $k: $v'));
      buffer.writeln();
    }

    if (includeRelationships && relationships.isNotEmpty) {
      buffer.writeln('【人物关系】');
      relationships.forEach((k, v) => buffer.writeln('- $k: $v'));
      buffer.writeln();
    }

    if (includeLocations && locations.isNotEmpty) {
      buffer.writeln('【场景地点】');
      locations.forEach((k, v) => buffer.writeln('- $k: $v'));
      buffer.writeln();
    }

    if (includeForeshadowing && foreshadowing.isNotEmpty) {
      buffer.writeln('【伏笔/线索】');
      for (final f in foreshadowing) {
        buffer.writeln('- $f');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }
}

class NovelProject {
  final String id;
  final String name;
  final String? outline; // Generated outline text (user-editable)
  final String? outlineRequirement; // Last prompt used to generate outline
  final String? knowledgeBaseId; // Project-dedicated KB (not used by chat)
  final WorldContext worldContext; // Dynamic context that evolves with story
  final List<NovelChapter> chapters;
  final DateTime createdAt;

  NovelProject({
    required this.id,
    required this.name,
    this.outline,
    this.outlineRequirement,
    this.knowledgeBaseId,
    this.worldContext = const WorldContext(),
    this.chapters = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  NovelProject copyWith({
    String? id,
    String? name,
    String? outline,
    Object? outlineRequirement = _sentinel,
    String? knowledgeBaseId,
    WorldContext? worldContext,
    List<NovelChapter>? chapters,
    DateTime? createdAt,
  }) {
    return NovelProject(
      id: id ?? this.id,
      name: name ?? this.name,
      outline: outline ?? this.outline,
      outlineRequirement: outlineRequirement == _sentinel
          ? this.outlineRequirement
          : outlineRequirement as String?,
      knowledgeBaseId: knowledgeBaseId ?? this.knowledgeBaseId,
      worldContext: worldContext ?? this.worldContext,
      chapters: chapters ?? this.chapters,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static NovelProject create(String name, {WorldContext? worldContext}) {
    return NovelProject(
      id: const Uuid().v4(),
      name: name,
      worldContext: worldContext ?? const WorldContext(),
      chapters: [], // No default chapter - user generates from outline
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'outline': outline,
        'outlineRequirement': outlineRequirement,
        'knowledgeBaseId': knowledgeBaseId,
        'worldContext': worldContext.toJson(),
        'chapters': chapters.map((c) => c.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory NovelProject.fromJson(Map<String, dynamic> json) => NovelProject(
        id: json['id'] as String,
        name: json['name'] as String,
        outline: json['outline'] as String?,
        outlineRequirement: json['outlineRequirement'] as String?,
        knowledgeBaseId: json['knowledgeBaseId'] as String?,
        worldContext: json['worldContext'] != null
            ? WorldContext.fromJson(
                json['worldContext'] as Map<String, dynamic>)
            : const WorldContext(),
        chapters: (json['chapters'] as List<dynamic>?)
                ?.map((c) => NovelChapter.fromJson(c as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class NovelWritingState {
  final List<NovelProject> projects;
  final String? selectedProjectId;
  final String? selectedChapterId;
  final String? selectedTaskId;
  final List<NovelTask> allTasks;
  final bool isRunning;
  final bool isPaused;
  final bool isReviewEnabled;
  final bool isDecomposing; // 新增：拆解中状态
  final bool isGeneratingOutline; // 新增：生成大纲中状态
  final String? decomposeStatus; // 当前拆解阶段说明
  final int decomposeCurrentBatch; // 从 0 开始，展示时 +1
  final int decomposeTotalBatches; // 总批次数

  // Model Configurations
  final NovelModelConfig? outlineModel;
  final NovelModelConfig? decomposeModel;
  final NovelModelConfig? writerModel;
  final NovelModelConfig? reviewerModel;

  // Novel-specific prompt presets (separate from chat presets)
  final List<NovelPromptPreset> promptPresets;
  final String? activePromptPresetId;

  const NovelWritingState({
    this.projects = const [],
    this.selectedProjectId,
    this.selectedChapterId,
    this.selectedTaskId,
    this.allTasks = const [],
    this.isRunning = false,
    this.isPaused = false,
    this.isReviewEnabled = false,
    this.isDecomposing = false,
    this.isGeneratingOutline = false,
    this.decomposeStatus,
    this.decomposeCurrentBatch = 0,
    this.decomposeTotalBatches = 0,
    this.outlineModel,
    this.decomposeModel,
    this.writerModel,
    this.reviewerModel,
    this.promptPresets = const [],
    this.activePromptPresetId,
  });

  NovelProject? get selectedProject =>
      projects.where((p) => p.id == selectedProjectId).firstOrNull;

  NovelChapter? get selectedChapter => selectedProject?.chapters
      .where((c) => c.id == selectedChapterId)
      .firstOrNull;

  NovelTask? get selectedTask =>
      allTasks.where((t) => t.id == selectedTaskId).firstOrNull;

  List<NovelTask> tasksForChapter(String chapterId) =>
      allTasks.where((t) => t.chapterId == chapterId).toList();

  NovelWritingState copyWith({
    List<NovelProject>? projects,
    Object? selectedProjectId = _sentinel,
    Object? selectedChapterId = _sentinel,
    Object? selectedTaskId = _sentinel,
    List<NovelTask>? allTasks,
    bool? isRunning,
    bool? isPaused,
    bool? isReviewEnabled,
    bool? isDecomposing,
    bool? isGeneratingOutline,
    Object? decomposeStatus = _sentinel,
    int? decomposeCurrentBatch,
    int? decomposeTotalBatches,
    Object? outlineModel = _sentinel,
    Object? decomposeModel = _sentinel,
    Object? writerModel = _sentinel,
    Object? reviewerModel = _sentinel,
    List<NovelPromptPreset>? promptPresets,
    Object? activePromptPresetId = _sentinel,
  }) {
    return NovelWritingState(
      projects: projects ?? this.projects,
      selectedProjectId: selectedProjectId == _sentinel
          ? this.selectedProjectId
          : selectedProjectId as String?,
      selectedChapterId: selectedChapterId == _sentinel
          ? this.selectedChapterId
          : selectedChapterId as String?,
      selectedTaskId: selectedTaskId == _sentinel
          ? this.selectedTaskId
          : selectedTaskId as String?,
      allTasks: allTasks ?? this.allTasks,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      isReviewEnabled: isReviewEnabled ?? this.isReviewEnabled,
      isDecomposing: isDecomposing ?? this.isDecomposing,
      isGeneratingOutline: isGeneratingOutline ?? this.isGeneratingOutline,
      decomposeStatus: decomposeStatus == _sentinel
          ? this.decomposeStatus
          : decomposeStatus as String?,
      decomposeCurrentBatch:
          decomposeCurrentBatch ?? this.decomposeCurrentBatch,
      decomposeTotalBatches:
          decomposeTotalBatches ?? this.decomposeTotalBatches,
      outlineModel: outlineModel == _sentinel
          ? this.outlineModel
          : outlineModel as NovelModelConfig?,
      decomposeModel: decomposeModel == _sentinel
          ? this.decomposeModel
          : decomposeModel as NovelModelConfig?,
      writerModel: writerModel == _sentinel
          ? this.writerModel
          : writerModel as NovelModelConfig?,
      reviewerModel: reviewerModel == _sentinel
          ? this.reviewerModel
          : reviewerModel as NovelModelConfig?,
      promptPresets: promptPresets ?? this.promptPresets,
      activePromptPresetId: activePromptPresetId == _sentinel
          ? this.activePromptPresetId
          : activePromptPresetId as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'projects': projects.map((p) => p.toJson()).toList(),
        'selectedProjectId': selectedProjectId,
        'selectedChapterId': selectedChapterId,
        'selectedTaskId': selectedTaskId,
        'allTasks': allTasks.map((t) => t.toJson()).toList(),
        'isReviewEnabled': isReviewEnabled,
        'decomposeStatus': decomposeStatus,
        'decomposeCurrentBatch': decomposeCurrentBatch,
        'decomposeTotalBatches': decomposeTotalBatches,
        'outlineModel': outlineModel?.toJson(),
        'decomposeModel': decomposeModel?.toJson(),
        'writerModel': writerModel?.toJson(),
        'reviewerModel': reviewerModel?.toJson(),
        'promptPresets': promptPresets.map((p) => p.toJson()).toList(),
        'activePromptPresetId': activePromptPresetId,
      };

  factory NovelWritingState.fromJson(Map<String, dynamic> json) =>
      NovelWritingState(
        projects: (json['projects'] as List<dynamic>?)
                ?.map((p) => NovelProject.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
        selectedProjectId: json['selectedProjectId'] as String?,
        selectedChapterId: json['selectedChapterId'] as String?,
        selectedTaskId: json['selectedTaskId'] as String?,
        allTasks: (json['allTasks'] as List<dynamic>?)
                ?.map((t) => NovelTask.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [],
        isReviewEnabled: json['isReviewEnabled'] as bool? ?? false,
        decomposeStatus: json['decomposeStatus'] as String?,
        decomposeCurrentBatch: json['decomposeCurrentBatch'] as int? ?? 0,
        decomposeTotalBatches: json['decomposeTotalBatches'] as int? ?? 0,
        outlineModel: json['outlineModel'] != null
            ? NovelModelConfig.fromJson(
                json['outlineModel'] as Map<String, dynamic>)
            : null,
        decomposeModel: json['decomposeModel'] != null
            ? NovelModelConfig.fromJson(
                json['decomposeModel'] as Map<String, dynamic>)
            : null,
        writerModel: json['writerModel'] != null
            ? NovelModelConfig.fromJson(
                json['writerModel'] as Map<String, dynamic>)
            : null,
        reviewerModel: json['reviewerModel'] != null
            ? NovelModelConfig.fromJson(
                json['reviewerModel'] as Map<String, dynamic>)
            : null,
        promptPresets: (json['promptPresets'] as List<dynamic>?)
                ?.map((p) =>
                    NovelPromptPreset.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
        activePromptPresetId: json['activePromptPresetId'] as String?,
      );
}
